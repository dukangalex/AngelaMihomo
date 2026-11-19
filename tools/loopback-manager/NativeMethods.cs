using System;
using System.Runtime.InteropServices;

namespace AngelaMihomo.LoopbackManager
{
    /// <summary>
    /// P/Invoke declarations for the Network Isolation API (netfw.h,
    /// FirewallAPI.dll) plus the SID/console helpers the tool needs.
    /// Signatures follow the Microsoft Learn reference pages for
    /// NetworkIsolationEnumAppContainers, NetworkIsolationGetAppContainerConfig,
    /// NetworkIsolationSetAppContainerConfig and
    /// NetworkIsolationFreeAppContainers.
    /// </summary>
    internal static class NativeMethods
    {
        internal const uint ErrorSuccess = 0;

        // NETISO_FLAG_FORCE_COMPUTE_BINARIES (NETISO_FLAG enumeration, netfw.h):
        // compute all binaries before an app container is returned.
        internal const uint NetIsoFlagForceComputeBinaries = 0x1;

        // SE_GROUP_ENABLED (winnt.h): attribute carried by an enabled
        // SID_AND_ATTRIBUTES entry.
        internal const uint SeGroupEnabled = 0x00000004;

        internal const int AttachParentProcess = -1;

        // SID_AND_ATTRIBUTES (winnt.h): a SID pointer plus its attributes.
        [StructLayout(LayoutKind.Sequential)]
        internal struct SidAndAttributes
        {
            public IntPtr Sid;
            public uint Attributes;
        }

        // INET_FIREWALL_AC_CAPABILITIES (netfw.h).
        [StructLayout(LayoutKind.Sequential)]
        internal struct InetFirewallAcCapabilities
        {
            public uint Count;
            public IntPtr Capabilities; // PSID_AND_ATTRIBUTES
        }

        // INET_FIREWALL_AC_BINARIES (netfw.h).
        [StructLayout(LayoutKind.Sequential)]
        internal struct InetFirewallAcBinaries
        {
            public uint Count;
            public IntPtr Binaries; // LPWSTR*
        }

        // INET_FIREWALL_APP_CONTAINER (netfw.h). Field order and types match
        // the documented layout exactly; the string fields are LPWSTR.
        [StructLayout(LayoutKind.Sequential)]
        internal struct InetFirewallAppContainer
        {
            public IntPtr AppContainerSid; // SID*
            public IntPtr UserSid;         // SID*
            [MarshalAs(UnmanagedType.LPWStr)]
            public string AppContainerName; // package family name
            [MarshalAs(UnmanagedType.LPWStr)]
            public string DisplayName;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string Description;
            public InetFirewallAcCapabilities Capabilities;
            public InetFirewallAcBinaries Binaries;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string WorkingDirectory;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string PackageFullName;
        }

        // DWORD NetworkIsolationEnumAppContainers(
        //   [in]  DWORD                        Flags,
        //   [out] DWORD                        *pdwNumPublicAppCs,
        //   [out] PINET_FIREWALL_APP_CONTAINER *ppPublicAppCs);
        // The returned array must be released with
        // NetworkIsolationFreeAppContainers.
        [DllImport("FirewallAPI.dll", ExactSpelling = true)]
        internal static extern uint NetworkIsolationEnumAppContainers(
            uint flags,
            out uint pdwNumPublicAppCs,
            out IntPtr ppPublicAppCs);

        // DWORD NetworkIsolationGetAppContainerConfig(
        //   [out] DWORD               *pdwNumPublicAppCs,
        //   [out] PSID_AND_ATTRIBUTES *appContainerSids);
        // The caller owns the returned memory: per the documentation sample,
        // every SID and the array itself are freed with HeapFree on the
        // process heap.
        [DllImport("FirewallAPI.dll", ExactSpelling = true)]
        internal static extern uint NetworkIsolationGetAppContainerConfig(
            out uint pdwNumPublicAppCs,
            out IntPtr appContainerSids);

        // DWORD NetworkIsolationSetAppContainerConfig(
        //   [in] DWORD               dwNumPublicAppCs,
        //   [in] PSID_AND_ATTRIBUTES appContainerSids);
        // Replaces the whole exemption set, so callers must first read the
        // current configuration and carry over the entries they keep.
        [DllImport("FirewallAPI.dll", ExactSpelling = true)]
        internal static extern uint NetworkIsolationSetAppContainerConfig(
            uint dwNumPublicAppCs,
            SidAndAttributes[] appContainerSids);

        // DWORD NetworkIsolationFreeAppContainers(
        //   [in] PINET_FIREWALL_APP_CONTAINER pPublicAppCs);
        [DllImport("FirewallAPI.dll", ExactSpelling = true)]
        internal static extern uint NetworkIsolationFreeAppContainers(
            IntPtr pPublicAppCs);

        // BOOL ConvertSidToStringSidW(PSID Sid, LPWSTR *StringSid);
        // The returned string is LocalFree'd by the caller.
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool ConvertSidToStringSid(IntPtr sid, out IntPtr stringSid);

        [DllImport("kernel32.dll", ExactSpelling = true)]
        internal static extern IntPtr GetProcessHeap();

        [DllImport("kernel32.dll", ExactSpelling = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool HeapFree(IntPtr hHeap, uint dwFlags, IntPtr lpMem);

        [DllImport("kernel32.dll", ExactSpelling = true)]
        internal static extern IntPtr LocalFree(IntPtr hMem);

        // Lets the GUI-subsystem binary write CLI output to the console of
        // the process that launched it.
        [DllImport("kernel32.dll", ExactSpelling = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool AttachConsole(int dwProcessId);
    }
}
