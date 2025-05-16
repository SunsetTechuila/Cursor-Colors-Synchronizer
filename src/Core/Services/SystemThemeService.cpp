#include "SystemThemeService.hpp"
#include "RegistryService.hpp"
#include <Windows.h>
#include <stdexcept>

namespace CCS {
SystemThemeService::~SystemThemeService() { StopMonitoring(); }

ThemeMode SystemThemeService::GetTheme() {
  auto themeValue = RegistryService::GetDwordValueOrThrow(
      THEME_REGISTRY_PATH, L"SystemUsesLightTheme");

  return themeValue == 0 ? ThemeMode::Dark : ThemeMode::Light;
}

std::string SystemThemeService::GetThemeString() {
  switch (GetTheme()) {
  case ThemeMode::Light:
    return "light";
  case ThemeMode::Dark:
    return "dark";
  }
}

Color SystemThemeService::GetAccentColor() {
  auto colorValue = RegistryService::GetDwordValueOrThrow(
      ACCENT_COLOR_REGISTRY_PATH, L"AccentColor");

  // Extract RGB values
  // Windows stores accent color as RGBA with different byte order
  uint8_t a = (colorValue >> 24) & 0xFF;
  uint8_t b = (colorValue >> 16) & 0xFF;
  uint8_t g = (colorValue >> 8) & 0xFF;
  uint8_t r = colorValue & 0xFF;

  return Color(r, g, b);
}

void SystemThemeService::StartMonitoringThemeChanges(
    ThemeChangeCallback callback) {
  m_ThemeChangeCallbacks.push_back(callback);

  if (!m_IsMonitoringTheme) {
    m_IsMonitoringTheme = true;

    m_Watchers.push_back(RegistryService::WaitForRegistryKeyChange(THEME_REGISTRY_PATH, [this]() {
      if (m_IsMonitoringTheme) {
        ThemeMode currentTheme = GetTheme();

        for (const auto &callback : m_ThemeChangeCallbacks) {
          callback(currentTheme);
        }
      }
    }));
  }
}

void SystemThemeService::StartMonitoringAccentColorChanges(
    AccentColorChangeCallback callback) {
  m_AccentColorChangeCallbacks.push_back(callback);

  if (!m_IsMonitoringAccentColor) {
    m_IsMonitoringAccentColor = true;

    m_Watchers.push_back(RegistryService::WaitForRegistryKeyChange(
        ACCENT_COLOR_REGISTRY_PATH, [this]() {
          if (m_IsMonitoringAccentColor) {
            Color currentColor = GetAccentColor();

            for (const auto &callback : m_AccentColorChangeCallbacks) {
              callback(currentColor);
            }
          }
        }));
  }
}

void SystemThemeService::StopMonitoring() {
  m_IsMonitoringTheme = false;
  m_IsMonitoringAccentColor = false;

  m_ThemeChangeCallbacks.clear();
  m_AccentColorChangeCallbacks.clear();

  for (const auto &watcherId : m_Watchers) {
    RegistryService::StopWatching(watcherId);
  }
}
} // namespace CCS