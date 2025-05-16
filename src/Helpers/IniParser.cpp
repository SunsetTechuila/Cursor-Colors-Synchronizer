#include "IniParser.hpp"
#include "../Core/Services/FileSystemService.hpp"
#include "./Utils.hpp"

namespace CCS {

IniParser::IniData IniParser::ParseFile(const std::filesystem::path &filePath) {
  IniData result;

  if (!std::filesystem::exists(filePath)) {
    return result;
  }

  std::vector<std::string> lines = FileSystemService::ReadAllLines(filePath);

  for (const auto &line : lines) {
    // Skip empty lines
    if (line.empty()) {
      continue;
    }

    // Process key-value pairs
    size_t equalPos = line.find('=');
    if (equalPos != std::string::npos) {
      std::string key = Utils::Trim(line.substr(0, equalPos));
      std::string value = Utils::Trim(line.substr(equalPos + 1));

      result[key] = value;
    }
  }

  return result;
}

void IniParser::WriteFile(const std::filesystem::path &filePath,
                          const IniData &data)
{
  std::vector<std::string> lines;
  // create array of lines
  for (const auto &pair : data)
  {
    lines.push_back(pair.first + "=" + pair.second);
  }
  FileSystemService::WriteAllLines(filePath, lines);
}
} // namespace CCS