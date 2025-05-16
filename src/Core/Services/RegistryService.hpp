#pragma once

#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <vector>
#include <Windows.h>

namespace CCS {
class RegistryService {
public:
  // Registry key watcher identifier type
  using WatcherId = size_t;

  static std::optional<std::wstring> GetStringValue(const std::wstring &path,
                                                    const std::wstring &name);
  static std::wstring GetStringValueOrThrow(const std::wstring &path,
                                            const std::wstring &name);
  static std::optional<DWORD> GetDwordValue(const std::wstring &path,
                                            const std::wstring &name);
  static DWORD GetDwordValueOrThrow(const std::wstring &path,
                                    const std::wstring &name);

  static bool SetStringValue(const std::wstring &path, const std::wstring &name,
                             const std::wstring &value);
  static bool SetDwordValue(const std::wstring &path, const std::wstring &name,
                            DWORD value);

  static bool KeyExists(const std::wstring &path);
  static bool CreateKey(const std::wstring &path);

  static WatcherId WaitForRegistryKeyChange(const std::wstring &path,
                                            std::function<void()> callback);
  static void StopWatching(WatcherId watcherId);
  static void StopAllWatching();

private:
  // Registry watcher data structure
  struct RegistryWatcher
  {
    std::wstring path;
    std::function<void()> callback;
    bool isWatching;
    std::thread watcherThread;
  };

  static std::mutex watchersMutex;
  static std::map<WatcherId, RegistryWatcher> watchers;
  static WatcherId nextWatcherId;
};
} // namespace CCS