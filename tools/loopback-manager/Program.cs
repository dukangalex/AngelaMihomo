using System;
using System.ComponentModel;
using System.Windows.Forms;

namespace AngelaMihomo.LoopbackManager
{
    internal static class Program
    {
        // Exit codes, kept in sync with the usage text.
        internal const int ExitOk = 0;
        internal const int ExitUsage = 1;
        internal const int ExitNotFound = 2;
        internal const int ExitApiFailure = 3;

        [STAThread]
        private static int Main(string[] args)
        {
            if (args.Length > 0)
            {
                // The binary is a GUI-subsystem executable; attach to the
                // caller's console so CLI output and exit codes behave the
                // way scripts expect.
                NativeMethods.AttachConsole(NativeMethods.AttachParentProcess);
                int code = Cli.Run(args);
                Console.Out.Flush();
                Console.Error.Flush();
                return code;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
            return ExitOk;
        }
    }

    /// <summary>
    /// Command-line mode: list / add / remove. Output is plain text, one
    /// record per line, so results can be verified by scripts.
    /// </summary>
    internal static class Cli
    {
        public static int Run(string[] args)
        {
            string command = args[0].ToLowerInvariant();
            try
            {
                if (command == "list" && args.Length == 1)
                {
                    return List();
                }
                if (command == "add" && args.Length == 2)
                {
                    return Change(args[1], true);
                }
                if (command == "remove" && args.Length == 2)
                {
                    return Change(args[1], false);
                }
            }
            catch (Win32Exception ex)
            {
                Console.Error.WriteLine("error: " + ex.Message);
                return Program.ExitApiFailure;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("error: " + ex.Message);
                return Program.ExitApiFailure;
            }

            Console.Error.WriteLine(Strings.Usage);
            return Program.ExitUsage;
        }

        private static int List()
        {
            foreach (AppContainerInfo info in Loopback.ListContainers())
            {
                Console.WriteLine(
                    (info.LoopbackExempt ? "exempt" : "blocked") + "\t" +
                    info.Name + "\t" +
                    info.SidString + "\t" +
                    info.DisplayName);
            }
            return Program.ExitOk;
        }

        private static int Change(string target, bool exempt)
        {
            AppContainerInfo info;
            if (!Loopback.SetExemption(target, exempt, out info))
            {
                Console.Error.WriteLine(Strings.NotFound(target));
                return Program.ExitNotFound;
            }
            Console.WriteLine(
                (exempt ? "exempt" : "blocked") + "\t" +
                info.Name + "\t" +
                info.SidString + "\t" +
                info.DisplayName);
            return Program.ExitOk;
        }
    }
}
