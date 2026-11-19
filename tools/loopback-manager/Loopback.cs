using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace AngelaMihomo.LoopbackManager
{
    /// <summary>One app container as shown by the GUI and the CLI.</summary>
    internal sealed class AppContainerInfo
    {
        public string Name;        // package family name
        public string DisplayName; // friendly name (may be empty)
        public string Description; // may be empty
        public string SidString;   // S-1-15-2-... form
        public bool LoopbackExempt;
    }

    /// <summary>
    /// Loopback exemption logic built on the documented Network Isolation
    /// API semantics: enumerate app containers, read the current exemption
    /// configuration, and write back a complete replacement set that
    /// preserves every entry the caller did not ask to change.
    /// </summary>
    internal static class Loopback
    {
        /// <summary>Enumerate all app containers with their exemption state.</summary>
        public static List<AppContainerInfo> ListContainers()
        {
            using (ContainersSnapshot containers = ContainersSnapshot.Load())
            using (ConfigSnapshot config = ConfigSnapshot.Load())
            {
                HashSet<string> exempt = new HashSet<string>(
                    config.SidStrings, StringComparer.OrdinalIgnoreCase);
                List<AppContainerInfo> result = new List<AppContainerInfo>();
                foreach (ContainerEntry entry in containers.Entries)
                {
                    AppContainerInfo info = new AppContainerInfo();
                    info.Name = entry.Name;
                    info.DisplayName = entry.DisplayName;
                    info.Description = entry.Description;
                    info.SidString = entry.SidString;
                    info.LoopbackExempt =
                        entry.SidString != null && exempt.Contains(entry.SidString);
                    result.Add(info);
                }
                result.Sort(CompareByDisplayName);
                return result;
            }
        }

        /// <summary>
        /// Add or remove one container's loopback exemption. The target is
        /// matched by package family name first, then by SID string.
        /// Returns false when no container matches. Adding an already
        /// exempt container (or removing a non-exempt one) is a no-op
        /// success, so scripts can run idempotently.
        /// </summary>
        public static bool SetExemption(string nameOrSid, bool exempt, out AppContainerInfo target)
        {
            target = null;
            using (ContainersSnapshot containers = ContainersSnapshot.Load())
            using (ConfigSnapshot config = ConfigSnapshot.Load())
            {
                ContainerEntry match = Find(containers.Entries, nameOrSid);
                if (match == null)
                {
                    return false;
                }

                target = new AppContainerInfo();
                target.Name = match.Name;
                target.DisplayName = match.DisplayName;
                target.Description = match.Description;
                target.SidString = match.SidString;
                target.LoopbackExempt = exempt;

                bool present = ContainsSid(config.Entries, match.SidString);
                if (present == exempt)
                {
                    return true; // already in the requested state
                }

                List<NativeMethods.SidAndAttributes> desired =
                    new List<NativeMethods.SidAndAttributes>();
                foreach (ConfigEntry entry in config.Entries)
                {
                    if (!exempt && SidEquals(entry.SidString, match.SidString))
                    {
                        continue; // dropping the target
                    }
                    desired.Add(entry.Raw);
                }
                if (exempt)
                {
                    NativeMethods.SidAndAttributes added =
                        new NativeMethods.SidAndAttributes();
                    added.Sid = match.Sid;
                    added.Attributes = NativeMethods.SeGroupEnabled;
                    desired.Add(added);
                }
                WriteConfig(desired);
                return true;
            }
        }

        /// <summary>
        /// Replace the exemption set with exactly the given package family
        /// names (used by the GUI's Save). Exemptions whose SID does not
        /// belong to any currently enumerated container are preserved:
        /// the configuration is machine state we must not silently drop.
        /// </summary>
        public static void SaveExemptions(ICollection<string> desiredNames)
        {
            HashSet<string> wanted = new HashSet<string>(
                desiredNames, StringComparer.OrdinalIgnoreCase);
            using (ContainersSnapshot containers = ContainersSnapshot.Load())
            using (ConfigSnapshot config = ConfigSnapshot.Load())
            {
                HashSet<string> knownSids = new HashSet<string>(
                    StringComparer.OrdinalIgnoreCase);
                foreach (ContainerEntry entry in containers.Entries)
                {
                    if (entry.SidString != null)
                    {
                        knownSids.Add(entry.SidString);
                    }
                }

                List<NativeMethods.SidAndAttributes> desired =
                    new List<NativeMethods.SidAndAttributes>();
                HashSet<string> covered = new HashSet<string>(
                    StringComparer.OrdinalIgnoreCase);
                foreach (ConfigEntry entry in config.Entries)
                {
                    bool known = entry.SidString != null && knownSids.Contains(entry.SidString);
                    if (known && !IsWanted(containers.Entries, wanted, entry.SidString))
                    {
                        continue; // a listed container the user unchecked
                    }
                    desired.Add(entry.Raw);
                    if (entry.SidString != null)
                    {
                        covered.Add(entry.SidString);
                    }
                }
                foreach (ContainerEntry entry in containers.Entries)
                {
                    if (entry.SidString == null || covered.Contains(entry.SidString))
                    {
                        continue;
                    }
                    if (!wanted.Contains(entry.Name))
                    {
                        continue;
                    }
                    NativeMethods.SidAndAttributes added =
                        new NativeMethods.SidAndAttributes();
                    added.Sid = entry.Sid;
                    added.Attributes = NativeMethods.SeGroupEnabled;
                    desired.Add(added);
                }
                WriteConfig(desired);
            }
        }

        private static bool IsWanted(
            List<ContainerEntry> containers, HashSet<string> wantedNames, string sidString)
        {
            foreach (ContainerEntry entry in containers)
            {
                if (SidEquals(entry.SidString, sidString))
                {
                    return wantedNames.Contains(entry.Name);
                }
            }
            return false;
        }

        private static ContainerEntry Find(List<ContainerEntry> entries, string nameOrSid)
        {
            foreach (ContainerEntry entry in entries)
            {
                if (string.Equals(entry.Name, nameOrSid, StringComparison.OrdinalIgnoreCase))
                {
                    return entry;
                }
            }
            foreach (ContainerEntry entry in entries)
            {
                if (SidEquals(entry.SidString, nameOrSid))
                {
                    return entry;
                }
            }
            return null;
        }

        private static bool ContainsSid(List<ConfigEntry> entries, string sidString)
        {
            foreach (ConfigEntry entry in entries)
            {
                if (SidEquals(entry.SidString, sidString))
                {
                    return true;
                }
            }
            return false;
        }

        private static bool SidEquals(string a, string b)
        {
            return a != null && b != null &&
                string.Equals(a, b, StringComparison.OrdinalIgnoreCase);
        }

        private static int CompareByDisplayName(AppContainerInfo a, AppContainerInfo b)
        {
            string ka = string.IsNullOrEmpty(a.DisplayName) ? a.Name : a.DisplayName;
            string kb = string.IsNullOrEmpty(b.DisplayName) ? b.Name : b.DisplayName;
            int byName = string.Compare(ka, kb, StringComparison.CurrentCultureIgnoreCase);
            if (byName != 0)
            {
                return byName;
            }
            return string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
        }

        private static void WriteConfig(List<NativeMethods.SidAndAttributes> desired)
        {
            NativeMethods.SidAndAttributes[] array = desired.ToArray();
            uint err = NativeMethods.NetworkIsolationSetAppContainerConfig(
                (uint)array.Length, array);
            if (err != NativeMethods.ErrorSuccess)
            {
                throw new Win32Exception(
                    (int)err, "NetworkIsolationSetAppContainerConfig failed, error " + err);
            }
        }

        internal static string SidToString(IntPtr sid)
        {
            if (sid == IntPtr.Zero)
            {
                return null;
            }
            IntPtr text;
            if (!NativeMethods.ConvertSidToStringSid(sid, out text))
            {
                return null;
            }
            try
            {
                return Marshal.PtrToStringUni(text);
            }
            finally
            {
                NativeMethods.LocalFree(text);
            }
        }

        private sealed class ContainerEntry
        {
            public IntPtr Sid;
            public string SidString;
            public string Name;
            public string DisplayName;
            public string Description;
        }

        /// <summary>
        /// Owns the array returned by NetworkIsolationEnumAppContainers
        /// until Dispose releases it with NetworkIsolationFreeAppContainers.
        /// Entry SID pointers are only valid while the snapshot lives.
        /// </summary>
        private sealed class ContainersSnapshot : IDisposable
        {
            public readonly List<ContainerEntry> Entries = new List<ContainerEntry>();
            private IntPtr _array;

            public static ContainersSnapshot Load()
            {
                ContainersSnapshot snapshot = new ContainersSnapshot();
                uint count;
                IntPtr array;
                uint err = NativeMethods.NetworkIsolationEnumAppContainers(
                    NativeMethods.NetIsoFlagForceComputeBinaries,
                    out count, out array);
                if (err != NativeMethods.ErrorSuccess)
                {
                    throw new Win32Exception(
                        (int)err, "NetworkIsolationEnumAppContainers failed, error " + err);
                }
                snapshot._array = array;
                int size = Marshal.SizeOf(typeof(NativeMethods.InetFirewallAppContainer));
                for (uint i = 0; i < count; i++)
                {
                    IntPtr p = new IntPtr(array.ToInt64() + (long)i * size);
                    NativeMethods.InetFirewallAppContainer raw =
                        (NativeMethods.InetFirewallAppContainer)Marshal.PtrToStructure(
                            p, typeof(NativeMethods.InetFirewallAppContainer));
                    ContainerEntry entry = new ContainerEntry();
                    entry.Sid = raw.AppContainerSid;
                    entry.SidString = SidToString(raw.AppContainerSid);
                    entry.Name = raw.AppContainerName ?? string.Empty;
                    entry.DisplayName = raw.DisplayName ?? string.Empty;
                    entry.Description = raw.Description ?? string.Empty;
                    snapshot.Entries.Add(entry);
                }
                return snapshot;
            }

            public void Dispose()
            {
                if (_array != IntPtr.Zero)
                {
                    NativeMethods.NetworkIsolationFreeAppContainers(_array);
                    _array = IntPtr.Zero;
                }
            }
        }

        private sealed class ConfigEntry
        {
            public NativeMethods.SidAndAttributes Raw;
            public string SidString;
        }

        /// <summary>
        /// Owns the array returned by NetworkIsolationGetAppContainerConfig.
        /// Following the documentation sample, Dispose frees every SID and
        /// the array itself with HeapFree on the process heap.
        /// </summary>
        private sealed class ConfigSnapshot : IDisposable
        {
            public readonly List<ConfigEntry> Entries = new List<ConfigEntry>();
            public readonly List<string> SidStrings = new List<string>();
            private IntPtr _array;
            private uint _count;

            public static ConfigSnapshot Load()
            {
                ConfigSnapshot snapshot = new ConfigSnapshot();
                uint count;
                IntPtr array;
                uint err = NativeMethods.NetworkIsolationGetAppContainerConfig(
                    out count, out array);
                if (err != NativeMethods.ErrorSuccess)
                {
                    throw new Win32Exception(
                        (int)err, "NetworkIsolationGetAppContainerConfig failed, error " + err);
                }
                snapshot._array = array;
                snapshot._count = count;
                int size = Marshal.SizeOf(typeof(NativeMethods.SidAndAttributes));
                for (uint i = 0; i < count; i++)
                {
                    IntPtr p = new IntPtr(array.ToInt64() + (long)i * size);
                    NativeMethods.SidAndAttributes raw =
                        (NativeMethods.SidAndAttributes)Marshal.PtrToStructure(
                            p, typeof(NativeMethods.SidAndAttributes));
                    ConfigEntry entry = new ConfigEntry();
                    entry.Raw = raw;
                    entry.SidString = SidToString(raw.Sid);
                    snapshot.Entries.Add(entry);
                    if (entry.SidString != null)
                    {
                        snapshot.SidStrings.Add(entry.SidString);
                    }
                }
                return snapshot;
            }

            public void Dispose()
            {
                if (_array == IntPtr.Zero)
                {
                    return;
                }
                IntPtr heap = NativeMethods.GetProcessHeap();
                int size = Marshal.SizeOf(typeof(NativeMethods.SidAndAttributes));
                for (uint i = 0; i < _count; i++)
                {
                    IntPtr p = new IntPtr(_array.ToInt64() + (long)i * size);
                    NativeMethods.SidAndAttributes raw =
                        (NativeMethods.SidAndAttributes)Marshal.PtrToStructure(
                            p, typeof(NativeMethods.SidAndAttributes));
                    if (raw.Sid != IntPtr.Zero)
                    {
                        NativeMethods.HeapFree(heap, 0, raw.Sid);
                    }
                }
                NativeMethods.HeapFree(heap, 0, _array);
                _array = IntPtr.Zero;
            }
        }
    }
}
