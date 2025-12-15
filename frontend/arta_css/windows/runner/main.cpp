#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <gdiplus.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Initialize GDI+ for runtime image loading (used for high-resolution icons).
  ULONG_PTR gdi_plus_token = 0;
  Gdiplus::GdiplusStartupInput gdi_startup_input;
  Gdiplus::GdiplusStartup(&gdi_plus_token, &gdi_startup_input, nullptr);

  // Ensure only a single instance of the application runs on Windows.
  // Use a named mutex in the Local namespace. If an instance already exists,
  // find its window and bring it to the foreground, then exit.
  HANDLE single_instance_mutex =
      ::CreateMutexW(nullptr, FALSE, L"Local\\VServeSingleInstanceMutex");
  if (single_instance_mutex != nullptr) {
    if (::GetLastError() == ERROR_ALREADY_EXISTS) {
      // Try to find the existing window by the window class name used
      // by the Win32 runner and restore/foreground it.
      HWND existing = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
      if (existing) {
        if (::IsIconic(existing)) {
          ::ShowWindow(existing, SW_RESTORE);
        }
        ::SetForegroundWindow(existing);
      }
      return EXIT_SUCCESS;
    }
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"V-Serve", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance_mutex != nullptr) {
    ::CloseHandle(single_instance_mutex);
    single_instance_mutex = nullptr;
  }
  if (gdi_plus_token) {
    Gdiplus::GdiplusShutdown(gdi_plus_token);
  }
  return EXIT_SUCCESS;
}
