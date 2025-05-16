#pragma once

#include "../Core/Configuration/PreferencesManager.hpp"
#include "../Core/Services/CursorService.hpp"
#include "../Core/Services/LocalizationService.hpp"
#include "../Core/Services/SystemThemeService.hpp"
#include "DialogService.hpp"

#include <memory>

namespace CCS {

class ConsoleUI {
public:
  ConsoleUI(std::shared_ptr<DialogService> dialogService,
            std::shared_ptr<PreferencesManager> preferencesManager,
            std::shared_ptr<CursorService> cursorService,
            std::shared_ptr<SystemThemeService> themeService,
            std::shared_ptr<LocalizationService> localizationService);

  // Display the setup wizard to collect user preferences
  void ShowSetupWizard();

  // Display the main menu
  void ShowMainMenu();

  // Apply current settings
  void ApplySettings();

  // Show about information
  void ShowAbout() const;

private:
  // Helper methods for the setup wizard
  void PromptForCursorTheme();
  void PromptForCursorSize();
  void PromptForTailVersion();
  void PromptForAlternatePrecision();
  void PromptForBackgroundSync();

  // Helper methods for background sync
  // void EnableBackgroundSync();
  // void DisableBackgroundSync();

  std::shared_ptr<DialogService> m_DialogService;
  std::shared_ptr<PreferencesManager> m_PreferencesManager;
  std::shared_ptr<CursorService> m_CursorService;
  std::shared_ptr<SystemThemeService> m_SystemThemeService;
  std::shared_ptr<LocalizationService> m_LocalizationService;
};

} // namespace CCS