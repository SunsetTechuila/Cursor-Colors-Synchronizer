#include "PathProvider.hpp"
#include "PreferencesManager.hpp"

namespace CCS {
PathProvider::PathProvider(const std::filesystem::path &rootPath)
    : RootPath(rootPath), ResourcesPath(RootPath / "Resources"),
      CursorsPath(ResourcesPath / "Cursors"),
      EditedCursorsPath(CursorsPath / "Edited"),
      OriginalCursorsRootPath(CursorsPath / "Original"),
      DiffsRootPath(ResourcesPath / "Diffs"),
      LocalizationsPath(ResourcesPath / "Localizations"),
      PreferencesPath(RootPath / "prefs.ini"),
      ListenerPath(RootPath / "BackgroundListener.exe") {}

std::filesystem::path PathProvider::GetOriginalCursorsFolder(
    const std::shared_ptr<PreferencesManager> &preferences) const {
  std::filesystem::path path = OriginalCursorsRootPath;

  // Add theme path
  path /= preferences->GetEffectiveCursorTheme();

  // Add version path
  if (preferences->useTailVersion) {
    path /= "tail";
  } else {
    path /= "default";
    path /= preferences->CursorSizeToString(preferences->cursorSize);
  }

  return path;
}

std::filesystem::path PathProvider::GetDiffsFolder(
    const std::shared_ptr<PreferencesManager> &preferences) const {
  std::filesystem::path path = DiffsRootPath;

  // Add version path
  if (preferences->useTailVersion) {
    path /= "tail";
  } else {
    path /= "default";
    path /= preferences->CursorSizeToString(preferences->cursorSize);
  }

  return path;
}
} // namespace CCS