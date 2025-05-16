#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <iostream>
#include <string>

#include "DialogService.hpp"

namespace CCS {
void DialogService::ShowMessage(const std::string &message) const {
  std::cout << std::endl
            << "Message:" << std::endl
            << message << std::endl
            << std::endl;

  system("pause");
}

void DialogService::ShowSuccess(const std::string &message) const {
  std::cout << std::endl
            << "Success:" << std::endl
            << message << std::endl
            << std::endl;

  system("pause");
}

void DialogService::ShowWarning(const std::string &message) const {
  std::cout << std::endl
            << "Warning:" << std::endl
            << message << std::endl
            << std::endl;

  system("pause");
}

void DialogService::ShowError(const std::string &message) const {
  std::cerr << std::endl
            << "Error:" << std::endl
            << message << std::endl
            << std::endl;

  system("pause");
}

// Template specialization for most common types
template <>
std::string DialogService::ShowChoice(
    const std::string &title,
    const std::vector<std::pair<std::string, std::string>> &options,
    const std::string &defaultOption) const {
  // Clear console for better readability
  system("cls");

  std::cout << "\n=== " << title << " ===\n";

  // Display options
  for (size_t i = 0; i < options.size(); ++i) {
    std::cout << (i + 1) << ". " << options[i].second;
    if (options[i].first == defaultOption) {
      std::cout << " (default)";
    }
    std::cout << std::endl;
  }

  // Get user choice
  while (true) {
    std::cout << "\nEnter your choice (1-" << options.size() << "): ";
    std::string input;
    std::getline(std::cin, input);

    // If empty, return default
    if (input.empty()) {
      return defaultOption;
    }

    // Try to parse as number
    try {
      int choice = std::stoi(input);
      if (choice >= 1 && choice <= static_cast<int>(options.size())) {
        return options[choice - 1].first;
      }
    } catch (...) {
      // Try to match by string
      for (const auto &option : options) {
        if (option.first == input || option.second == input) {
          return option.first;
        }
      }
    }

    std::cout << "Invalid choice. Please try again." << std::endl;
  }
}

template <>
bool DialogService::ShowChoice(
    const std::string &title,
    const std::vector<std::pair<bool, std::string>> &options,
    const bool &defaultOption) const {
  // Clear console for better readability
  system("cls");

  std::cout << "\n=== " << title << " ===\n";

  // Extract yes/no options
  std::string yesText;
  std::string noText;

  for (const auto &option : options) {
    if (option.first) {
      yesText = option.second;
    } else {
      noText = option.second;
    }
  }

  // Use default values if not provided
  if (yesText.empty()) {
    yesText = "Yes";
  }

  if (noText.empty()) {
    noText = "No";
  }

  // Format the prompt with default highlighted
  std::string defaultMark = defaultOption ? yesText : noText;
  std::cout << yesText << "/" << noText << " [default: " << defaultMark
            << "]: ";

  // Get user input
  while (true) {
    std::string input;
    std::getline(std::cin, input);

    // If empty, return default
    if (input.empty()) {
      return defaultOption;
    }

    // Convert to lowercase for case-insensitive comparison
    std::transform(input.begin(), input.end(), input.begin(),
                   [](unsigned char c) { return std::tolower(c); });

    if (input == "y" || input == "yes" || input == "true" || input == "1") {
      return true;
    } else if (input == "n" || input == "no" || input == "false" ||
               input == "0") {
      return false;
    }

    std::cout << "Invalid choice. Please enter " << yesText << " or " << noText
              << ": ";
  }
}

template <>
int DialogService::ShowChoice(
    const std::string &title,
    const std::vector<std::pair<int, std::string>> &options,
    const int &defaultOption) const {
  // Clear console for better readability
  system("cls");

  std::cout << "\n=== " << title << " ===\n";

  // Display options
  for (size_t i = 0; i < options.size(); ++i) {
    std::cout << (i + 1) << ". " << options[i].second;
    if (options[i].first == defaultOption) {
      std::cout << " (default)";
    }
    std::cout << std::endl;
  }

  // Get user choice
  while (true) {
    std::cout << "\nEnter your choice (1-" << options.size() << "): ";
    std::string input;
    std::getline(std::cin, input);

    // If empty, return default
    if (input.empty()) {
      return defaultOption;
    }

    // Try to parse as number
    try {
      int choice = std::stoi(input);
      if (choice >= 1 && choice <= static_cast<int>(options.size())) {
        return options[choice - 1].first;
      }
    } catch (...) {
      // Invalid input
    }

    std::cout << "Invalid choice. Please try again." << std::endl;
  }
}

} // namespace CCS