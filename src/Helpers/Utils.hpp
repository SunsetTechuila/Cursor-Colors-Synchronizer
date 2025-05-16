#pragma once

#include <Windows.h>
#include <string>
#include <vector>

namespace CCS::Utils {
// String utilities
std::string WideStringToString(const std::wstring &stringToConvert);
std::string ToLower(const std::string &stringToLower);
std::string Trim(const std::string &stringToTrim);
bool StringToBool(const std::string &inputString);

// Windows utilities
bool IsRunningAsAdmin();
bool RunAsAdmin(const std::wstring &path, const std::wstring &args = L"");
void HideConsoleWindow();
void ShowConsoleWindow();
std::string GetSystemErrorMessage(DWORD errorCode);
} // namespace CCS::Utils