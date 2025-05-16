#pragma once

#include <functional>
#include <string>
#include <vector>

#include "./RegistryService.hpp"
#include "../Models/Color.hpp"

namespace CCS {
enum class ThemeMode { Light, Dark };

using ThemeChangeCallback = std::function<void(ThemeMode)>;
using AccentColorChangeCallback = std::function<void(const Color &)>;

class SystemThemeService {
public:
  SystemThemeService() = default;
  ~SystemThemeService();

  static ThemeMode GetTheme();
  static std::string GetThemeString();
  static Color GetAccentColor();

  void StartMonitoringThemeChanges(ThemeChangeCallback callback);
  void StartMonitoringAccentColorChanges(AccentColorChangeCallback callback);
  void StopMonitoring();

private:
  bool m_IsMonitoringTheme = false;
  bool m_IsMonitoringAccentColor = false;

  std::vector<RegistryService::WatcherId> m_Watchers;
  std::vector<ThemeChangeCallback> m_ThemeChangeCallbacks;
  std::vector<AccentColorChangeCallback> m_AccentColorChangeCallbacks;

  static constexpr const wchar_t *THEME_REGISTRY_PATH =
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
  static constexpr const wchar_t *ACCENT_COLOR_REGISTRY_PATH =
      L"Software\\Microsoft\\Windows\\DWM";
};
} // namespace CCS