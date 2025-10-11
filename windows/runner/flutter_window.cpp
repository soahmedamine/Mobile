#include "flutter_window.h"

#include <optional>
<<<<<<< HEAD
=======
#include <iostream>
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
<<<<<<< HEAD
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
=======
    : project_(project) {
  std::cout << "FlutterWindow constructor called" << std::endl;
}

FlutterWindow::~FlutterWindow() {
  std::cout << "FlutterWindow destructor called" << std::endl;
}

bool FlutterWindow::OnCreate() {
  std::cout << "FlutterWindow::OnCreate() called" << std::endl;
  
  if (!Win32Window::OnCreate()) {
    std::cerr << "Win32Window::OnCreate() failed" << std::endl;
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a
    return false;
  }

  RECT frame = GetClientArea();
<<<<<<< HEAD

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
=======
  std::cout << "Window client area: width=" << (frame.right - frame.left) 
            << ", height=" << (frame.bottom - frame.top) << std::endl;

  try {
    // The size here must match the window dimensions to avoid unnecessary surface
    // creation / destruction in the startup path.
    std::cout << "Creating Flutter view controller..." << std::endl;
    flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
        frame.right - frame.left, frame.bottom - frame.top, project_);
    
    // Ensure that basic setup of the controller was successful.
    if (!flutter_controller_->engine()) {
      std::cerr << "Failed to create Flutter engine" << std::endl;
      return false;
    }
    
    if (!flutter_controller_->view()) {
      std::cerr << "Failed to create Flutter view" << std::endl;
      return false;
    }
    
    std::cout << "Registering plugins..." << std::endl;
    RegisterPlugins(flutter_controller_->engine());
    
    HWND flutter_view = flutter_controller_->view()->GetNativeWindow();
    if (!flutter_view) {
      std::cerr << "Failed to get Flutter view handle" << std::endl;
      return false;
    }
    
    std::cout << "Setting child content..." << std::endl;
    SetChildContent(flutter_view);

    // Set up callback to show the window when the first frame is rendered
    flutter_controller_->engine()->SetNextFrameCallback([&]() {
      std::cout << "First frame rendered, showing window" << std::endl;
      this->Show();
    });

    // Force a redraw to ensure the window is shown
    std::cout << "Forcing redraw..." << std::endl;
    flutter_controller_->ForceRedraw();
    
    std::cout << "Window creation completed successfully" << std::endl;
    return true;
  } catch (const std::exception& e) {
    std::cerr << "Exception in FlutterWindow::OnCreate(): " << e.what() << std::endl;
    return false;
  } catch (...) {
    std::cerr << "Unknown exception in FlutterWindow::OnCreate()" << std::endl;
    return false;
  }
}

void FlutterWindow::OnDestroy() {
  std::cout << "FlutterWindow::OnDestroy() called" << std::endl;
  
  if (flutter_controller_) {
    std::cout << "Destroying Flutter controller..." << std::endl;
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
<<<<<<< HEAD
=======
  std::cout << "Window destroyed" << std::endl;
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
