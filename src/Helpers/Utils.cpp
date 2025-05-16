#include "Utils.hpp"

#include <algorithm>
#include <cctype>
#include <codecvt>
#include <filesystem>
#include <locale>
#include <regex>
#include <sstream>

namespace CCS::Utils {
std::string WideStringToString(const std::wstring &stringToConvert) {
  if (stringToConvert.empty())
    return std::string();

  const int size_needed =
      WideCharToMultiByte(CP_UTF8, 0, &stringToConvert[0],
                          (int)stringToConvert.size(), NULL, 0, NULL, NULL);
  std::string convertedString(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, &stringToConvert[0],
                      (int)stringToConvert.size(), &convertedString[0],
                      size_needed, NULL, NULL);

  return convertedString;
}

std::string ToLower(const std::string &stringToLower) {
  std::string loweredString = stringToLower;
  std::transform(
      loweredString.begin(), loweredString.end(), loweredString.begin(),
      [](unsigned char character) { return std::tolower(character); });
  return loweredString;
}

std::string Trim(const std::string &stringToTrim) {
  static const std::regex trimRegex("^\\s+|\\s+$");
  return std::regex_replace(stringToTrim, trimRegex, "");
}

bool StringToBool(const std::string &string) {
  std::string loweredString = ToLower(string);
  return loweredString == "true" || loweredString == "1" ||
         loweredString == "yes";
}

bool IsRunningAsAdmin() {
  BOOL isAdmin = FALSE;
  SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;
  PSID AdministratorsGroup;

  if (AllocateAndInitializeSid(&NtAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                               DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
                               &AdministratorsGroup)) {
    if (!CheckTokenMembership(NULL, AdministratorsGroup, &isAdmin)) {
      isAdmin = FALSE;
    }
    FreeSid(AdministratorsGroup);
  }

  return isAdmin != 0;
}

bool RunAsAdmin(const std::wstring &path, const std::wstring &args) {
  return ShellExecuteW(NULL, L"runas", path.c_str(),
                       args.empty() ? NULL : args.c_str(), NULL,
                       SW_SHOWNORMAL) > (HINSTANCE)32;
}

void HideConsoleWindow() { ShowWindow(GetConsoleWindow(), SW_HIDE); }

void ShowConsoleWindow() { ShowWindow(GetConsoleWindow(), SW_SHOW); }

std::string GetSystemErrorMessage(DWORD errorCode) {
  LPSTR messageBuffer = nullptr;

  size_t size = FormatMessageA(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL, errorCode, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      (LPSTR)&messageBuffer, 0, NULL);

  std::string message(messageBuffer, size);
  LocalFree(messageBuffer);

  return message;
}
} // namespace CCS::Utils