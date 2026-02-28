#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shellapi.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

// app_links uses WM_COPYDATA with this dwData value to deliver URIs.
static constexpr ULONG_PTR kAppLinkMessage = WM_USER + 2;

// Convert a local file path to a file:/// URI string (wide).
// Replaces backslashes with forward slashes and percent-encodes spaces.
static std::wstring FilePathToUri(const std::wstring& path) {
  std::wstring uri = L"file:///";
  for (wchar_t ch : path) {
    if (ch == L'\\') {
      uri += L'/';
    } else if (ch == L' ') {
      uri += L"%20";
    } else {
      uri += ch;
    }
  }
  return uri;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // --- Single-instance enforcement ---
  HANDLE mutex = ::CreateMutexW(nullptr, FALSE,
                                L"com.marquis.editor.instance");
  if (mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    // Another instance is already running.
    // Parse command-line for a file path argument.
    int argc = 0;
    LPWSTR* argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);

    if (argv != nullptr && argc > 1) {
      // Find the existing Flutter window and send the file path as a URI.
      HWND existing = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
      if (existing != nullptr) {
        std::wstring uri = FilePathToUri(argv[1]);

        COPYDATASTRUCT cds = {};
        cds.dwData = kAppLinkMessage;
        cds.cbData = static_cast<DWORD>(
            (uri.size() + 1) * sizeof(wchar_t));
        cds.lpData = const_cast<wchar_t*>(uri.c_str());

        ::SendMessageW(existing, WM_COPYDATA,
                        reinterpret_cast<WPARAM>(nullptr),
                        reinterpret_cast<LPARAM>(&cds));

        // Bring the existing window to the foreground.
        if (::IsIconic(existing)) {
          ::ShowWindow(existing, SW_RESTORE);
        }
        ::SetForegroundWindow(existing);
      }
      ::LocalFree(argv);
    }

    ::CloseHandle(mutex);
    return EXIT_SUCCESS;
  }

  // --- First instance: continue normally ---

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"marquis", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (mutex != nullptr) {
    ::CloseHandle(mutex);
  }
  return EXIT_SUCCESS;
}
