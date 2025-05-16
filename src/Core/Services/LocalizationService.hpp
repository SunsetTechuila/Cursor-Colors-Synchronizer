#pragma once

#include <filesystem>
#include <memory>
#include <string>
#include <unordered_map>

namespace CCS {

class LocalizationService {
public:
  LocalizationService(const std::filesystem::path &localizationPath);

  std::string GetString(const std::string &key) const;

  void LoadStrings(const std::string &languageCode);

private:
  std::filesystem::path m_LocalizationPath;
  std::string m_CurrentLanguage;
  std::unordered_map<std::string, std::string> m_Strings;
};

} // namespace CCS