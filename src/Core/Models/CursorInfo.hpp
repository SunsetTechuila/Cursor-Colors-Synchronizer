#pragma once

// #include <filesystem>
#include <string>

namespace CCS {
class CursorInfo {
public:
  CursorInfo(const std::string &cursorName, const std::string &cursorPath);

  const std::string &GetName() const { return m_Name; }
  const std::string &GetPath() const { return m_Path; }
  const std::string &GetFileName() const { return m_FileName; }

private:
  std::string m_Name;
  std::string m_Path;
  std::string m_FileName;
};
} // namespace CCS