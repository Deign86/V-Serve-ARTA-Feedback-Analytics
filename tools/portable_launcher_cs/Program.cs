using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;

class Program
{
    static int Main(string[] args)
    {
        try
        {
            string marker = "VSSFXZIPMARKER_v1";
            string exePath = string.Empty;
            try
            {
                var asm = Assembly.GetEntryAssembly();
                if (asm != null && !string.IsNullOrEmpty(asm.Location))
                {
                    exePath = asm.Location;
                }
            }
            catch { }

            if (string.IsNullOrEmpty(exePath))
            {
                // Fallback to process main module path
                try
                {
                    exePath = Process.GetCurrentProcess().MainModule?.FileName ?? string.Empty;
                }
                catch { }
            }

            if (string.IsNullOrEmpty(exePath) || !File.Exists(exePath))
            {
                Console.Error.WriteLine("Unable to determine launcher executable path.");
                return 2;
            }

            var all = File.ReadAllBytes(exePath);

            // Search for marker from the end
            var markerBytes = System.Text.Encoding.UTF8.GetBytes(marker);
            int markerPos = -1;
            for (int i = all.Length - markerBytes.Length - 1; i >= 0; --i)
            {
                bool ok = true;
                for (int j = 0; j < markerBytes.Length; ++j)
                {
                    if (all[i + j] != markerBytes[j]) { ok = false; break; }
                }
                if (ok) { markerPos = i; break; }
            }

            if (markerPos < 0)
            {
                Console.Error.WriteLine("No embedded package found.");
                return 3;
            }

            int zipStart = markerPos + markerBytes.Length;
            if (zipStart >= all.Length)
            {
                Console.Error.WriteLine("Package marker found but no ZIP data.");
                return 4;
            }

            string tempRoot = Path.Combine(Path.GetTempPath(), "VServePortable_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(tempRoot);
            string zipPath = Path.Combine(tempRoot, "app.zip");
            using (var fs = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                fs.Write(all, zipStart, all.Length - zipStart);
            }

            // Extract
            string extractDir = Path.Combine(tempRoot, "app");
            Directory.CreateDirectory(extractDir);
            ZipFile.ExtractToDirectory(zipPath, extractDir);

            // Launch the app
            string appExe = Path.Combine(extractDir, "V-Serve.exe");
            if (!File.Exists(appExe))
            {
                // Try checking in runner folder
                appExe = Directory.GetFiles(extractDir, "V-Serve.exe", SearchOption.AllDirectories).FirstOrDefault();
            }
            if (appExe == null || !File.Exists(appExe))
            {
                Console.Error.WriteLine("Could not find V-Serve.exe in package.");
                return 5;
            }

            var pi = new ProcessStartInfo(appExe)
            {
                WorkingDirectory = Path.GetDirectoryName(appExe) ?? extractDir,
                UseShellExecute = false,
            };
            Process.Start(pi);

            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("Launcher error: " + ex.ToString());
            return 99;
        }
    }
}
