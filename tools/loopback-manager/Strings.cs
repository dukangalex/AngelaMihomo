using System.Globalization;

namespace AngelaMihomo.LoopbackManager
{
    /// <summary>
    /// Bilingual UI text. Chinese (any zh UI culture) gets the Chinese
    /// strings, every other culture gets English. Wording is original to
    /// this tool.
    /// </summary>
    internal static class Strings
    {
        private static bool Zh
        {
            get
            {
                return CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "zh";
            }
        }

        private static string Pick(string zh, string en)
        {
            return Zh ? zh : en;
        }

        public static string AppTitle
        {
            get { return Pick("AngelaMihomo 回环豁免管理", "AngelaMihomo Loopback Exemptions"); }
        }

        public static string ColumnApp
        {
            get { return Pick("应用", "App"); }
        }

        public static string ColumnPackage
        {
            get { return Pick("包系列名", "Package family name"); }
        }

        public static string ColumnStatus
        {
            get { return Pick("回环状态", "Loopback"); }
        }

        public static string StatusExempt
        {
            get { return Pick("已豁免", "Exempt"); }
        }

        public static string StatusBlocked
        {
            get { return Pick("未豁免", "Not exempt"); }
        }

        public static string RefreshButton
        {
            get { return Pick("刷新", "Refresh"); }
        }

        public static string SaveButton
        {
            get { return Pick("保存", "Save"); }
        }

        public static string CloseButton
        {
            get { return Pick("关闭", "Close"); }
        }

        public static string IntroText
        {
            get
            {
                return Pick(
                    "勾选允许通过本机回环地址连接 AngelaMihomo 代理端口的应用，保存后生效。",
                    "Tick the apps allowed to reach the AngelaMihomo proxy port through the loopback address, then save.");
            }
        }

        public static string SavedMessage
        {
            get { return Pick("已保存。", "Saved."); }
        }

        public static string LoadedMessage(int count)
        {
            return Zh
                ? "已加载 " + count + " 个应用容器。"
                : "Loaded " + count + " app containers.";
        }

        public static string ErrorTitle
        {
            get { return Pick("出错了", "Error"); }
        }

        public static string Usage
        {
            get
            {
                return Pick(
                    "用法：AngelaMihomoLoopbackManager [list | add <名称|SID> | remove <名称|SID>]\n" +
                    "  无参数        打开图形界面\n" +
                    "  list          列出全部应用容器及其回环豁免状态\n" +
                    "  add <目标>    为指定应用容器添加回环豁免\n" +
                    "  remove <目标> 移除指定应用容器的回环豁免\n" +
                    "退出码：0 成功，1 用法错误，2 找不到目标，3 系统调用失败",
                    "Usage: AngelaMihomoLoopbackManager [list | add <name|SID> | remove <name|SID>]\n" +
                    "  (no arguments)  open the graphical interface\n" +
                    "  list            list all app containers and their loopback exemption state\n" +
                    "  add <target>    grant a loopback exemption to the given app container\n" +
                    "  remove <target> revoke the loopback exemption of the given app container\n" +
                    "Exit codes: 0 success, 1 usage error, 2 target not found, 3 system call failed");
            }
        }

        public static string NotFound(string target)
        {
            return Zh
                ? "找不到应用容器：" + target
                : "App container not found: " + target;
        }

        public static string Added(string name)
        {
            return Zh ? "已添加豁免：" + name : "Exemption added: " + name;
        }

        public static string Removed(string name)
        {
            return Zh ? "已移除豁免：" + name : "Exemption removed: " + name;
        }

        public static string Unchanged(string name)
        {
            return Zh ? "状态未变：" + name : "No change: " + name;
        }
    }
}
