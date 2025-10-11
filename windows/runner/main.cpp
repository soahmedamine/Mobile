#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
<<<<<<< HEAD
=======
#include <iostream>
#include <cstdlib>
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
<<<<<<< HEAD
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
  if (!window.Create(L"smart_travel_weather_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
=======
  if (!::AttachConsole(ATTACH_PARENT_PROCESS)) {
    if (::IsDebuggerPresent()) {
      CreateAndAttachConsole();
    } else {
      // If we can't attach to a console, create one
      if (AllocConsole()) {
        FILE* fDummy;
        freopen_s(&fDummy, "CONOUT$", "w", stdout);
        freopen_s(&fDummy, "CONOUT$", "w", stderr);
        std::cout.clear();
        std::cerr.clear();
        std::wcout.clear();
        std::wcerr.clear();
      }
    }
  }

  std::cout << "Starting application..." << std::endl;

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  HRESULT hr = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(hr)) {
    std::cerr << "Failed to initialize COM: 0x" << std::hex << hr << std::endl;
    return EXIT_FAILURE;
  }

  try {
    std::cout << "Creating Flutter project..." << std::endl;
    flutter::DartProject project(L"data");

    std::vector<std::string> command_line_arguments = GetCommandLineArguments();
    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

    std::cout << "Creating Flutter window..." << std::endl;
    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    
    if (!window.Create(L"my_first_app", origin, size)) {
      std::cerr << "Failed to create window" << std::endl;
      return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);
    std::cout << "Window created successfully" << std::endl;

    // Main message loop
    ::MSG msg = {};
    while (::GetMessage(&msg, nullptr, 0, 0)) {
      ::TranslateMessage(&msg);
      ::DispatchMessage(&msg);
    }

    std::cout << "Shutting down..." << std::endl;
    ::CoUninitialize();
    return EXIT_SUCCESS;
  } catch (const std::exception& e) {
    std::cerr << "Unhandled exception: " << e.what() << std::endl;
    ::MessageBoxA(nullptr, e.what(), "Error", MB_ICONERROR);
    ::CoUninitialize();
    return EXIT_FAILURE;
  } catch (...) {
    std::cerr << "Unknown exception occurred" << std::endl;
    ::MessageBoxA(nullptr, "An unknown error occurred", "Error", MB_ICONERROR);
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a
}
