#include <Windows.h>
#include <atomic>
#include <chrono>
#include <filesystem>
#include <iostream>
#include <memory>
#include <thread>

#include "../Core/Configuration/PathProvider.hpp"
#include "../Core/Configuration/PreferencesManager.hpp"
#include "../Core/Models/Color.hpp"
#include "../Core/Services/CursorService.hpp"
#include "../Core/Services/SystemThemeService.hpp"
#include "../Helpers/Utils.hpp"

std::atomic<bool> g_Running = true;

// Signal handler for graceful shutdown
BOOL WINAPI ConsoleControlHandler(DWORD ctrlType) {
  if (ctrlType == CTRL_C_EVENT || ctrlType == CTRL_BREAK_EVENT ||
      ctrlType == CTRL_CLOSE_EVENT || ctrlType == CTRL_SHUTDOWN_EVENT) {
    g_Running = false;
    return TRUE;
  }
  return FALSE;
}

void EnsureAdminPrivileges() {
  BOOL isAdmin = CCS::Utils::IsRunningAsAdmin();

  if (!isAdmin) {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(NULL, exePath, MAX_PATH);
    CCS::Utils::RunAsAdmin(exePath);
    exit(0);
  }
}

int main(int argc, char *argv[]) {
  // Ensure application is running with administrator privileges
  EnsureAdminPrivileges();

  // Set up console control handler for graceful shutdown
  SetConsoleCtrlHandler(ConsoleControlHandler, TRUE);

  try {
    // Get executable path
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(NULL, exePath, MAX_PATH);
    std::filesystem::path executablePath(exePath);
    std::filesystem::path rootPath =
        executablePath.parent_path()
            .parent_path(); // Go up one level to reach root

    // Initialize services
    auto pathProvider = std::make_shared<CCS::PathProvider>(rootPath.string());
    auto preferencesManager = std::make_shared<CCS::PreferencesManager>(
        pathProvider->PreferencesPath);

    auto systemThemeService = std::make_shared<CCS::SystemThemeService>();
    auto cursorService =
        std::make_shared<CCS::CursorService>(pathProvider, preferencesManager);

    // Threads for monitoring theme and accent color changes
    std::thread themeThread;
    std::thread accentColorThread;

    // Only monitor theme changes if using system theme
    if (preferencesManager->cursorTheme ==
        CCS::PreferencesManager::CursorTheme::System) {
      CCS::ThemeMode lastTheme = systemThemeService->GetTheme();

      themeThread = std::thread([&]() {
        systemThemeService->StartMonitoringThemeChanges([&](CCS::ThemeMode newTheme) {
          if (lastTheme != newTheme) {
            std::cout << "System theme changed. Updating cursors..."
                      << std::endl;
            cursorService->CopyCursors();
            cursorService->EditCursors();
            cursorService->InstallCursors();
            lastTheme = newTheme;
          }
        });

        while (g_Running) {
          std::this_thread::sleep_for(std::chrono::seconds(1));
        }
      });
    }

    // Always monitor accent color changes
    CCS::Color lastAccentColor = systemThemeService->GetAccentColor();

    accentColorThread = std::thread([&]() {
      systemThemeService->StartMonitoringAccentColorChanges(
          [&](const CCS::Color &newColor) {
            if (lastAccentColor != newColor) {
              std::cout << "Accent color changed. Updating cursors..."
                        << std::endl;
              cursorService->EditCursors();
              cursorService->InstallCursors();
              lastAccentColor = CCS::Color(newColor.R, newColor.G, newColor.B);
            }
          });

      while (g_Running) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
      }
    });

    // Keep the main thread alive until signaled to exit
    while (g_Running) {
      std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    // Clean up threads
    systemThemeService->StopMonitoring();
    if (themeThread.joinable()) {
      themeThread.join();
    }
    if (accentColorThread.joinable()) {
      accentColorThread.join();
    }

    return 0;
  } catch (...) {
    return 1;
  }
}