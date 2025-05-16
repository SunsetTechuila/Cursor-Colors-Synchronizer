#include <algorithm>
#include <fstream>
#include <regex>
#include <sstream>
#include <stdexcept>
#include <Windows.h>

#include "LocalizationService.hpp"
#include "../../Helpers/IniParser.hpp"
#include "FileSystemService.hpp"

namespace CCS {
LocalizationService::LocalizationService(
    const std::filesystem::path &localizationPath): m_LocalizationPath(localizationPath)
{
  // TODO: Add support for multiple languages
  m_CurrentLanguage = "en-US";
  LoadStrings(m_CurrentLanguage);
}

std::string LocalizationService::GetString(const std::string &key) const {
  auto iterator = m_Strings.find(key);
  if (iterator != m_Strings.end()) {
    return iterator->second;
  }
  throw std::runtime_error("String not found: " + key);
}

void LocalizationService::LoadStrings(const std::string &languageCode) {
  std::filesystem::path filePath =
      m_LocalizationPath / languageCode / "Strings.ini";

  if (FileSystemService::FileExists(filePath)) {
    m_Strings = IniParser::ParseFile(filePath);
  } else {
    throw std::runtime_error("Localization file not found: " +
                             filePath.string());
  }
}
} // namespace CCS