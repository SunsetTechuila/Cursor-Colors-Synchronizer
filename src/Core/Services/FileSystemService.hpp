#pragma once

#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <vector>

namespace CCS {
class FileSystemService {
public:
  // Read/write functions
  static std::vector<uint8_t> ReadAllBytes(const std::filesystem::path &path);
  static void WriteAllBytes(const std::filesystem::path &path,
                            const std::vector<uint8_t> &bytes);
  static std::vector<std::string>
  ReadAllLines(const std::filesystem::path &path);
  static void WriteAllLines(const std::filesystem::path &path,
                            const std::vector<std::string> &lines);

  // File/directory operations
  static bool FileExists(const std::filesystem::path &path);
  static bool DirectoryExists(const std::filesystem::path &path);
  static void CreateDirectory(const std::filesystem::path &path);
  static void CopyFile(const std::filesystem::path &source,
                       const std::filesystem::path &destination,
                       bool overwrite = true);
  static void CopyFilesRecursively(const std::filesystem::path &source,
                                   const std::filesystem::path &destination,
                                   bool overwrite = true);
  static void DeleteFile(const std::filesystem::path &path);
  static void RenameFile(const std::filesystem::path &oldPath,
                         const std::filesystem::path &newPath);

  // Path utilities
  static std::string ConvertEnvironmentPath(const std::string &path);
};
} // namespace CCS