#include <stdexcept>

#include "../../Helpers/IniParser.hpp"
#include "../../Helpers/Utils.hpp"
#include "../Services/SystemThemeService.hpp"
#include "PreferencesManager.hpp"

namespace CCS {
PreferencesManager::PreferencesManager(
    const std::filesystem::path &preferencesPath)
    : m_PreferencesPath(preferencesPath) {
  LoadPreferences();
}

PreferencesManager::~PreferencesManager() { SavePreferences(); }

std::string PreferencesManager::GetEffectiveCursorTheme() const {
  if (cursorTheme == CursorTheme::System) {
    return SystemThemeService::GetThemeString();
  }
  return CursorThemeToString(cursorTheme);
}

std::string PreferencesManager::CursorSizeToString(CursorSize cursorSize) {
  switch (cursorSize) {
  case CursorSize::Small:
    return "small";
  case CursorSize::Regular:
    return "regular";
  case CursorSize::Big:
    return "big";
  default:
    throw std::invalid_argument("Invalid cursor size" +
                                std::to_string(static_cast<int>(cursorSize)));
  }
}

std::string PreferencesManager::CursorThemeToString(CursorTheme cursorTheme) {
  switch (cursorTheme) {
  case CursorTheme::System:
    return "system";
  case CursorTheme::Light:
    return "light";
  case CursorTheme::Dark:
    return "dark";
  default:
    throw std::invalid_argument("Invalid cursor theme" +
                                std::to_string(static_cast<int>(cursorTheme)));
  }
}

PreferencesManager::CursorSize
PreferencesManager::StringToCursorSize(const std::string &cursorSizeString) {
  const std::string cursorSizeStringLowered = Utils::ToLower(cursorSizeString);

  if (cursorSizeStringLowered == "regular") {
    return CursorSize::Regular;
  }
  if (cursorSizeStringLowered == "big") {
    return CursorSize::Big;
  }
  if (cursorSizeStringLowered == "small") {
    return CursorSize::Small;
  }

  throw std::invalid_argument("Invalid cursor size: " + cursorSizeString);
}

PreferencesManager::CursorTheme
PreferencesManager::StringToCursorTheme(const std::string &cursorThemeString) {
  const std::string cursorThemeStringLowered =
      Utils::ToLower(cursorThemeString);

  if (cursorThemeStringLowered == "light") {
    return CursorTheme::Light;
  }
  if (cursorThemeStringLowered == "dark") {
    return CursorTheme::Dark;
  }
  if (cursorThemeStringLowered == "system") {
    return CursorTheme::System;
  }

  throw std::invalid_argument("Invalid cursor theme: " + cursorThemeString);
}

void PreferencesManager::LoadPreferences() {
  if (!std::filesystem::exists(m_PreferencesPath)) {
    // No preferences file exists yet, use defaults
    return;
  }

  const auto preferences = IniParser::ParseFile(m_PreferencesPath);

  const auto useTailVersionIterator = preferences.find("UseTailVersion");
  if (useTailVersionIterator != preferences.end()) {
    useTailVersion = Utils::StringToBool(useTailVersionIterator->second);
  }

  const auto cursorSizeIterator = preferences.find("CursorSize");
  if (cursorSizeIterator != preferences.end()) {
    cursorSize = StringToCursorSize(cursorSizeIterator->second);
  }

  const auto useAltPrecisionIterator =
      preferences.find("UseAlternatePrecision");
  if (useAltPrecisionIterator != preferences.end()) {
    useAlternatePrecision =
        Utils::StringToBool(useAltPrecisionIterator->second);
  }

  const auto cursorThemeIterator = preferences.find("CursorTheme");
  if (cursorThemeIterator != preferences.end()) {
    cursorTheme = StringToCursorTheme(cursorThemeIterator->second);
  }

  const auto enableSyncIterator = preferences.find("EnableBackgroundSync");
  if (enableSyncIterator != preferences.end()) {
    enableBackgroundSync = Utils::StringToBool(enableSyncIterator->second);
  }
}

void PreferencesManager::SavePreferences() {
  IniParser::IniData iniData;

  iniData["UseTailVersion"] = useTailVersion;
  iniData["CursorSize"] = CursorSizeToString(cursorSize);
  iniData["UseAlternatePrecision"] = useAlternatePrecision;
  iniData["CursorTheme"] = CursorThemeToString(cursorTheme);
  iniData["EnableBackgroundSync"] = enableBackgroundSync;

  IniParser::WriteFile(m_PreferencesPath, iniData);
}
} // namespace CCS