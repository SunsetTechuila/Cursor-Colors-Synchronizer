#include <Windows.h>
#include <filesystem>
#include <iostream>
#include <memory>

#include "Core/Configuration/PathProvider.hpp"
#include "Core/Configuration/PreferencesManager.hpp"
#include "Core/Services/CursorService.hpp"
#include "Core/Services/LocalizationService.hpp"
#include "Core/Services/SystemThemeService.hpp"
#include "Helpers/Utils.hpp"
#include "UI/ConsoleUI.hpp"
#include "UI/DialogService.hpp"

void EnsureAdminPrivileges() {
  BOOL isAdmin = CCS::Utils::IsRunningAsAdmin();

  if (!isAdmin) {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);
    CCS::Utils::RunAsAdmin(exePath);
    exit(0);
  }
}

int main(int argc, char *argv[]) {
  EnsureAdminPrivileges();
  
  wchar_t exePath[MAX_PATH];
  GetModuleFileNameW(nullptr, exePath, MAX_PATH);
  std::filesystem::path executablePath(exePath);
  std::filesystem::path rootPath = executablePath.parent_path();

  // Initialize services
  auto pathProvider = std::make_shared<CCS::PathProvider>(rootPath.string());
  auto preferencesManager =
      std::make_shared<CCS::PreferencesManager>(pathProvider->PreferencesPath);
  auto localizationService = std::make_shared<CCS::LocalizationService>(
      pathProvider->LocalizationsPath);
  auto themeService = std::make_shared<CCS::SystemThemeService>();
  auto cursorService =
      std::make_shared<CCS::CursorService>(pathProvider, preferencesManager);
  auto dialogService = std::make_shared<CCS::DialogService>();

  // Create UI and run setup wizard
  CCS::ConsoleUI consoleUI(dialogService, preferencesManager, cursorService,
                           themeService, localizationService);
  consoleUI.ShowSetupWizard();

  return 0;
}