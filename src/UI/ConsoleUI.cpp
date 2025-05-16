#include <Windows.h>
#include <iostream>

#include "ConsoleUI.hpp"

namespace CCS {
ConsoleUI::ConsoleUI(std::shared_ptr<DialogService> dialogService,
                     std::shared_ptr<PreferencesManager> preferencesManager,
                     std::shared_ptr<CursorService> cursorService,
                     std::shared_ptr<SystemThemeService> themeService,
                     std::shared_ptr<LocalizationService> localizationService)
    : m_DialogService(std::move(dialogService)),
      m_PreferencesManager(std::move(preferencesManager)),
      m_CursorService(std::move(cursorService)),
      m_SystemThemeService(std::move(themeService)),
      m_LocalizationService(std::move(localizationService)) {}

void ConsoleUI::ShowSetupWizard() {
  // Set the console title
  SetConsoleTitleA("Cursor Colors Synchronizer");

  // Clear the console
  system("cls");

  std::cout << "========================================" << std::endl;
  std::cout << "    Cursor Colors Synchronizer Setup    " << std::endl;
  std::cout << "========================================" << std::endl;
  std::cout << std::endl;

  // Prompt for settings
  PromptForCursorTheme();
  PromptForCursorSize();
  PromptForTailVersion();

  if (!m_PreferencesManager->useTailVersion) {
    PromptForAlternatePrecision();
  }

  // TODO: Uncomment when background sync is implemented
  // PromptForBackgroundSync();

  // Apply settings
  ApplySettings();

  // Show success message
  m_DialogService->ShowSuccess(
      m_LocalizationService->GetString("SuccessMessage"));

  // Show GitHub reminder
  std::cout << m_LocalizationService->GetString("GitHubReminderMessage")
            << std::endl;
}

void ConsoleUI::ShowMainMenu() {
  // Not implemented yet - would show a menu for changing settings
  // after initial setup
}

void ConsoleUI::ApplySettings() {
  // Save preferences
  m_PreferencesManager->SavePreferences();

  // Apply cursor customization
  m_CursorService->CopyCursors();
  m_CursorService->EditCursors();
  m_CursorService->InstallCursors();

  // Setup background listener if requested
  // if (m_PreferencesManager->enableBackgroundSync) {
  //   EnableBackgroundSync();
  // } else {
  //   DisableBackgroundSync();
  // }
}

void ConsoleUI::ShowAbout() const {
  std::cout << "Cursor Colors Synchronizer" << std::endl;
  std::cout << "Version 0.0.1" << std::endl;
  std::cout << "A tool to synchronize your cursor accent color and theme with "
               "Windows."
            << std::endl;
  std::cout << "https://github.com/SunsetTechuila/Cursor-Colors-Synchronizer"
            << std::endl;
}

void ConsoleUI::PromptForCursorTheme() {
  std::string title =
      m_LocalizationService->GetString("ChooseThemeDialogTitle");

  std::vector<std::pair<std::string, std::string>> options = {
      {"system", m_LocalizationService->GetString("System")},
      {"dark", m_LocalizationService->GetString("Dark")},
      {"light", m_LocalizationService->GetString("Light")}};

  std::string currentTheme = PreferencesManager::CursorThemeToString(
      m_PreferencesManager->cursorTheme);
  std::string choice =
      m_DialogService->ShowChoice(title, options, currentTheme);

  m_PreferencesManager->cursorTheme =
      PreferencesManager::StringToCursorTheme(choice);
}

void ConsoleUI::PromptForCursorSize() {
  // Only prompt for cursor size if not using tail version
  if (m_PreferencesManager->useTailVersion) {
    return;
  }

  std::string title = m_LocalizationService->GetString("ChooseSizeDialogTitle");

  std::vector<std::pair<std::string, std::string>> options = {
      {"small", m_LocalizationService->GetString("Small")},
      {"regular", m_LocalizationService->GetString("Regular")},
      {"big", m_LocalizationService->GetString("Big")}};

  std::string currentSize =
      PreferencesManager::CursorSizeToString(m_PreferencesManager->cursorSize);
  std::string choice = m_DialogService->ShowChoice(title, options, currentSize);

  m_PreferencesManager->cursorSize =
      PreferencesManager::StringToCursorSize(choice);
}

void ConsoleUI::PromptForTailVersion() {
  std::string title =
      m_LocalizationService->GetString("TailVersionDialogTitle");

  std::vector<std::pair<bool, std::string>> options = {
      {true, m_LocalizationService->GetString("Yes")},
      {false, m_LocalizationService->GetString("No")}};

  bool currentChoice = m_PreferencesManager->useTailVersion;
  bool choice = m_DialogService->ShowChoice(title, options, currentChoice);

  m_PreferencesManager->useTailVersion = choice;
}

void ConsoleUI::PromptForAlternatePrecision() {
  std::string title =
      m_LocalizationService->GetString("ChoosePrecisionDialogTitle");

  std::vector<std::pair<bool, std::string>> options = {
      {true, m_LocalizationService->GetString("Yes")},
      {false, m_LocalizationService->GetString("No")}};

  bool currentChoice = m_PreferencesManager->useAlternatePrecision;
  bool choice = m_DialogService->ShowChoice(title, options, currentChoice);

  m_PreferencesManager->useAlternatePrecision = choice;
}

void ConsoleUI::PromptForBackgroundSync() {
  // Only prompt for background sync if using system theme
  if (m_PreferencesManager->cursorTheme !=
      PreferencesManager::CursorTheme::System) {
    m_PreferencesManager->enableBackgroundSync = false;
    return;
  }

  std::string title = m_LocalizationService->GetString("ListenerDialogTitle");

  std::vector<std::pair<bool, std::string>> options = {
      {true, m_LocalizationService->GetString("Yes")},
      {false, m_LocalizationService->GetString("No")}};

  bool currentChoice = m_PreferencesManager->enableBackgroundSync;
  bool choice = m_DialogService->ShowChoice(title, options, currentChoice);

  m_PreferencesManager->enableBackgroundSync = choice;
}

// TODO: Implement background synchronization
// void ConsoleUI::EnableBackgroundSync() {
//   std::cout << "Background synchronization enabled." << std::endl;
//   std::cout << "The cursor will automatically update when system theme or "
//                "accent color changes."
//             << std::endl;
// }

// void ConsoleUI::DisableBackgroundSync() {
//   std::cout << "Background synchronization disabled." << std::endl;
// }

} // namespace CCS