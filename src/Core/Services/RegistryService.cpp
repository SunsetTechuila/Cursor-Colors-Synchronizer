#include "RegistryService.hpp"

#include <condition_variable>
#include <stdexcept>

namespace CCS {
  // Initialize static members
  std::mutex RegistryService::watchersMutex;
  std::map<RegistryService::WatcherId, RegistryService::RegistryWatcher> RegistryService::watchers;
  RegistryService::WatcherId RegistryService::nextWatcherId = 1;

  bool RegistryService::KeyExists(const std::wstring &path)
  {
    HKEY hKey;
    LONG result =
        RegOpenKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, KEY_READ, &hKey);

    if (result == ERROR_SUCCESS)
    {
      RegCloseKey(hKey);
      return true;
    }

    return false;
  }

  bool RegistryService::CreateKey(const std::wstring &path)
  {
    HKEY hKey;
    DWORD disposition;

    LONG result = RegCreateKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, nullptr,
                                  REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                                  &hKey, &disposition);

    if (result == ERROR_SUCCESS)
    {
      RegCloseKey(hKey);
      return true;
    }

    return false;
  }

std::optional<std::wstring>
RegistryService::GetStringValue(const std::wstring &path,
                                const std::wstring &name) {
  HKEY hKey;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, KEY_READ, &hKey) !=
      ERROR_SUCCESS) {
    return std::nullopt;
  }

  DWORD type;
  DWORD dataSize = 0;

  // First call to get the required buffer size
  LONG result =
      RegQueryValueExW(hKey, name.c_str(), nullptr, &type, nullptr, &dataSize);
  if (result != ERROR_SUCCESS || type != REG_SZ) {
    RegCloseKey(hKey);
    return std::nullopt;
  }

  // Allocate buffer and get the actual value
  std::vector<wchar_t> buffer(dataSize / sizeof(wchar_t) + 1);
  result = RegQueryValueExW(hKey, name.c_str(), nullptr, &type,
                            reinterpret_cast<LPBYTE>(buffer.data()), &dataSize);

  RegCloseKey(hKey);

  if (result != ERROR_SUCCESS) {
    return std::nullopt;
  }

  // Ensure null-terminated string
  buffer[dataSize / sizeof(wchar_t)] = L'\0';
  return std::wstring(buffer.data());
}

std::wstring RegistryService::GetStringValueOrThrow(const std::wstring &path,
                                                    const std::wstring &name) {
  auto value = GetStringValue(path, name);
  if (!value.has_value()) {
    std::string narrowPath(path.begin(), path.end());
    throw std::runtime_error("Failed to get string value from registry: " +
                             narrowPath);
  }
  return value.value();
}

std::optional<DWORD> RegistryService::GetDwordValue(const std::wstring &path,
                                                    const std::wstring &name) {
  HKEY hKey;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, KEY_READ, &hKey) !=
      ERROR_SUCCESS) {
    return std::nullopt;
  }

  DWORD type;
  DWORD data;
  DWORD dataSize = sizeof(data);

  LONG result = RegQueryValueExW(hKey, name.c_str(), nullptr, &type,
                                 reinterpret_cast<LPBYTE>(&data), &dataSize);

  RegCloseKey(hKey);

  if (result != ERROR_SUCCESS || type != REG_DWORD) {
    return std::nullopt;
  }

  return data;
}

DWORD RegistryService::GetDwordValueOrThrow(const std::wstring &path,
                                            const std::wstring &name) {
  auto value = GetDwordValue(path, name);
  if (!value.has_value()) {
    std::string narrowPath(path.begin(), path.end());
    throw std::runtime_error("Failed to get DWORD value from registry: " +
                             narrowPath);
  }
  return value.value();
}

bool RegistryService::SetStringValue(const std::wstring &path,
                                     const std::wstring &name,
                                     const std::wstring &value) {
  HKEY hKey;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, KEY_WRITE, &hKey) !=
      ERROR_SUCCESS) {
    return false;
  }

  const BYTE *data = reinterpret_cast<const BYTE *>(value.c_str());
  DWORD dataSize = static_cast<DWORD>((value.length() + 1) * sizeof(wchar_t));

  LONG result = RegSetValueExW(hKey, name.c_str(), 0, REG_SZ, data, dataSize);

  RegCloseKey(hKey);

  return result == ERROR_SUCCESS;
}

bool RegistryService::SetDwordValue(const std::wstring &path,
                                    const std::wstring &name, DWORD value) {
  HKEY hKey;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, KEY_WRITE, &hKey) !=
      ERROR_SUCCESS) {
    return false;
  }

  LONG result =
      RegSetValueExW(hKey, name.c_str(), 0, REG_DWORD,
                     reinterpret_cast<const BYTE *>(&value), sizeof(value));

  RegCloseKey(hKey);

  return result == ERROR_SUCCESS;
}

RegistryService::WatcherId RegistryService::WaitForRegistryKeyChange(
    const std::wstring &path, std::function<void()> callback)
{
  std::lock_guard<std::mutex> lock(watchersMutex);

  // Create a new watcher ID
  WatcherId id = nextWatcherId++;

  // Create and store the watcher
  RegistryWatcher watcher{
      path,
      callback,
      true};

  // Start the registry monitoring thread
  watcher.watcherThread = std::thread([id, path, callback]()
                                      {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, path.c_str(), 0, KEY_NOTIFY, &hKey) != ERROR_SUCCESS) {
      return;
    }

    bool isWatching = true;
    {
      std::lock_guard<std::mutex> threadLock(watchersMutex);
      if (watchers.find(id) != watchers.end()) {
        isWatching = watchers[id].isWatching;
      } else {
        // Watcher was removed before thread started
        RegCloseKey(hKey);
        return;
      }
    }

    while (isWatching) {
      // Wait for registry change notification
      HANDLE hEvent = CreateEvent(nullptr, TRUE, FALSE, nullptr);
      if (hEvent == nullptr) {
        RegCloseKey(hKey);
        return;
      }

      // Set up the notification
      LONG result = RegNotifyChangeKeyValue(
          hKey,      // Handle to registry key
          TRUE,      // Watch subtrees
          REG_NOTIFY_CHANGE_LAST_SET | REG_NOTIFY_CHANGE_NAME, // Watch for changes to values or names
          hEvent,    // Event to signal
          TRUE       // Asynchronous operation
      );

      if (result != ERROR_SUCCESS) {
        CloseHandle(hEvent);
        RegCloseKey(hKey);
        return;
      }

      // Wait for the event or stop signal
      if (WaitForSingleObject(hEvent, INFINITE) == WAIT_OBJECT_0) {
        // Check if we're still watching
        {
          std::lock_guard<std::mutex> threadLock(watchersMutex);
          if (watchers.find(id) != watchers.end()) {
            isWatching = watchers[id].isWatching;
          } else {
            isWatching = false;
          }
        }
        
        if (isWatching) {
          // Execute the callback
          callback();
        }
      }

      CloseHandle(hEvent);

      // Add a small delay to prevent excessive CPU usage if changes happen rapidly
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
      
      // Check if we should continue watching
      {
        std::lock_guard<std::mutex> threadLock(watchersMutex);
        if (watchers.find(id) != watchers.end()) {
          isWatching = watchers[id].isWatching;
        } else {
          isWatching = false;
        }
      }
    }

    RegCloseKey(hKey); });

  watcher.watcherThread.detach(); // Let the thread run independently
  watchers[id] = std::move(watcher);

  return id;
}

void RegistryService::StopWatching(WatcherId watcherId)
{
  std::lock_guard<std::mutex> lock(watchersMutex);

  auto iterator = watchers.find(watcherId);
  if (iterator != watchers.end())
  {
    iterator->second.isWatching = false;
    // The thread will exit on its own after checking isWatching flag
    watchers.erase(iterator);
  }
}

void RegistryService::StopAllWatching()
{
  std::lock_guard<std::mutex> lock(watchersMutex);

  // Mark all watchers as stopped
  for (auto &[id, watcher] : watchers)
  {
    watcher.isWatching = false;
  }

  // Clear the watchers map
  watchers.clear();
}
} // namespace CCS