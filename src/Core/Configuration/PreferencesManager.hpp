#pragma once

#include <filesystem>
#include <memory>
#include <string>

namespace CCS {
class PreferencesManager
    : public std::enable_shared_from_this<PreferencesManager> {
public:
  enum class CursorSize { Small, Regular, Big };
  enum class CursorTheme { System, Light, Dark };

  PreferencesManager(const std::filesystem::path &preferencesPath);
  ~PreferencesManager();

  bool useTailVersion = false;
  CursorSize cursorSize = CursorSize::Small;
  bool useAlternatePrecision = false;
  CursorTheme cursorTheme = CursorTheme::System;
  bool enableBackgroundSync = true;

  // Get the current effective theme (resolves "System" to actual theme)
  std::string GetEffectiveCursorTheme() const;

  static std::string CursorSizeToString(CursorSize cursorSize);
  static std::string CursorThemeToString(CursorTheme cursorTheme);

  static CursorSize StringToCursorSize(const std::string &cursorSizeString);
  static CursorTheme StringToCursorTheme(const std::string &cursorThemeString);

  void LoadPreferences();
  void SavePreferences();

private:
  std::filesystem::path m_PreferencesPath;
};
} // namespace CCS