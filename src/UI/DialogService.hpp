#pragma once

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

namespace CCS {

class DialogService {
public:
  DialogService() = default;

  // Show different types of dialogs
  void ShowMessage(const std::string &message) const;
  void ShowSuccess(const std::string &message) const;
  void ShowWarning(const std::string &message) const;
  void ShowError(const std::string &message) const;

  // Show choice dialog with options
  template <typename T>
  T ShowChoice(const std::string &title,
               const std::vector<std::pair<T, std::string>> &options,
               const T &defaultOption) const;
};

} // namespace CCS