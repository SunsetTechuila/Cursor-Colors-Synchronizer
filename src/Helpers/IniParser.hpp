#pragma once

#include <filesystem>
#include <string>
#include <unordered_map>

namespace CCS {

class IniParser {
public:
  using IniData = std::unordered_map<std::string, std::string>;

  static IniData ParseFile(const std::filesystem::path &filePath);
  static void WriteFile(const std::filesystem::path &filePath,
                        const IniData &data);
};

} // namespace CCS