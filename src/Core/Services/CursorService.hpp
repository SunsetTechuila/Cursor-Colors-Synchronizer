#pragma once

#include "../Configuration/PathProvider.hpp"
#include "../Configuration/PreferencesManager.hpp"
#include "../Models/Color.hpp"
#include "../Models/CursorInfo.hpp"

#include <filesystem>
#include <memory>
#include <string>
#include <vector>

namespace CCS {
class CursorService {
public:
  CursorService(std::shared_ptr<PathProvider> pathProvider,
                std::shared_ptr<PreferencesManager> preferencesManager);

  // Main cursor operations
  void CopyCursors();
  void EditCursors();
  void InstallCursors();
  void ResetToDefaultCursors();
  void SynchronizeCursorsWithSystem();

private:
  // Helper methods
  void EditCursor(const std::filesystem::path &cursorPath,
                  const std::filesystem::path &diffPath,
                  const Color &targetColor);
  void SetCursor(const std::string &cursorName, const std::string &cursorPath);
  void UpdateCursorSettings();

  // Get known cursors mapping
  std::vector<CursorInfo> GetDefaultCursors() const;
  std::vector<CursorInfo> GetEditedCursors() const;

  std::shared_ptr<PathProvider> m_PathProvider;
  std::shared_ptr<PreferencesManager> m_PreferencesManager;
};
} // namespace CCS