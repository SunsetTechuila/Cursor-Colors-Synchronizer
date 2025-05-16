#include <Windows.h>
#include <fstream>
#include <sstream>
#include <stdexcept>

#include "FileSystemService.hpp"

namespace CCS {
template <typename FileStream>
void openFile(FileStream &file, const std::filesystem::path &path,
              std::ios_base::openmode mode, const std::string &operation) {
  file.open(path, mode);
  if (!file.is_open()) {
    throw std::runtime_error("Could not " + operation +
                             " file: " + path.string());
  }
}

std::vector<uint8_t>
FileSystemService::ReadAllBytes(const std::filesystem::path &path) {
  std::ifstream file;
  openFile(file, path, std::ios::binary | std::ios::ate, "open");

  auto fileSize = file.tellg();
  std::vector<uint8_t> buffer(fileSize);

  file.seekg(0);
  file.read(reinterpret_cast<char *>(buffer.data()), fileSize);
  file.close();

  return buffer;
}

void FileSystemService::WriteAllBytes(const std::filesystem::path &path,
                                      const std::vector<uint8_t> &bytes) {
  std::ofstream file;
  openFile(file, path, std::ios::binary, "create");

  file.write(reinterpret_cast<const char *>(bytes.data()), bytes.size());
  file.close();
}

std::vector<std::string>
FileSystemService::ReadAllLines(const std::filesystem::path &path) {
  std::ifstream file;
  openFile(file, path, std::ios::in, "open");

  std::vector<std::string> lines;
  std::string line;

  while (std::getline(file, line)) {
    lines.push_back(line);
  }

  file.close();
  return lines;
}

void FileSystemService::WriteAllLines(const std::filesystem::path &path,
                                      const std::vector<std::string> &lines) {
  std::ofstream file;
  openFile(file, path, std::ios::out, "create");

  for (const auto &line : lines) {
    file << line << "\n";
  }

  file.close();
}

bool FileSystemService::FileExists(const std::filesystem::path &path) {
  return std::filesystem::exists(path) &&
         std::filesystem::is_regular_file(path);
}

bool FileSystemService::DirectoryExists(const std::filesystem::path &path) {
  return std::filesystem::exists(path) && std::filesystem::is_directory(path);
}

void FileSystemService::CreateDirectory(const std::filesystem::path &path) {
  std::filesystem::create_directories(path);
}

void FileSystemService::CopyFile(const std::filesystem::path &source,
                                 const std::filesystem::path &destination,
                                 bool overwrite) {
  std::filesystem::copy_options options =
      overwrite ? std::filesystem::copy_options::overwrite_existing
                : std::filesystem::copy_options::none;

  std::filesystem::copy_file(source, destination, options);
}

void FileSystemService::CopyFilesRecursively(
    const std::filesystem::path &source,
    const std::filesystem::path &destination, bool overwrite) {
  if (!DirectoryExists(source)) {
    throw std::runtime_error("Source directory does not exist: " +
                             source.string());
  }

  if (!DirectoryExists(destination)) {
    CreateDirectory(destination);
  }

  for (const auto &entry : std::filesystem::directory_iterator(source)) {
    auto destinationPath = destination / entry.path().filename();
    if (entry.is_directory()) {
      CopyFilesRecursively(entry.path(), destinationPath, overwrite);
    } else {
      CopyFile(entry.path(), destinationPath, overwrite);
    }
  }
}

void FileSystemService::DeleteFile(const std::filesystem::path &path) {
  std::filesystem::remove(path);
}

void FileSystemService::RenameFile(const std::filesystem::path &oldPath,
                                   const std::filesystem::path &newPath) {
  std::filesystem::rename(oldPath, newPath);
}

std::string FileSystemService::ConvertEnvironmentPath(const std::string &path) {
  std::string result = path;
  size_t startPos = 0;

  while ((startPos = result.find('%', startPos)) != std::string::npos) {
    size_t endPos = result.find('%', startPos + 1);
    if (endPos == std::string::npos)
      break;

    std::string envVarName = result.substr(startPos + 1, endPos - startPos - 1);

    char buffer[MAX_PATH];
    DWORD size = GetEnvironmentVariableA(envVarName.c_str(), buffer, MAX_PATH);

    if (size > 0) {
      std::string envVarValue(buffer, size);
      result.replace(startPos, endPos - startPos + 1, envVarValue);
      startPos += envVarValue.length();
    } else {
      // Environment variable not found, skip this one
      startPos = endPos + 1;
    }
  }

  return result;
}
} // namespace CCS