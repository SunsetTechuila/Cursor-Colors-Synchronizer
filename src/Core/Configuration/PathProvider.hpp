#pragma once

#include <filesystem>
#include <memory>

namespace CCS {
class PreferencesManager;

class PathProvider {
public:
  PathProvider(const std::filesystem::path &rootPath);

  const std::filesystem::path RootPath;
  const std::filesystem::path ResourcesPath;
  const std::filesystem::path CursorsPath;
  const std::filesystem::path EditedCursorsPath;
  const std::filesystem::path OriginalCursorsRootPath;
  const std::filesystem::path DiffsRootPath;
  const std::filesystem::path LocalizationsPath;
  const std::filesystem::path PreferencesPath;
  const std::filesystem::path ListenerPath;

  std::filesystem::path GetOriginalCursorsFolder(
      const std::shared_ptr<PreferencesManager> &preferences) const;
  std::filesystem::path
  GetDiffsFolder(const std::shared_ptr<PreferencesManager> &preferences) const;
};
} // namespace CCS
