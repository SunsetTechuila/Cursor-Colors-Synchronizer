#include <algorithm>
#include <cctype>
#include <filesystem>

#include "CursorInfo.hpp"

namespace CCS {
CursorInfo::CursorInfo(const std::string &cursorName,
                       const std::string &cursorPath)
    : m_Name(cursorName), m_Path(cursorPath) {
  // Extract just the filename from the path
  std::filesystem::path filePath(cursorPath);
  m_FileName = filePath.filename().string();
}
} // namespace CCS