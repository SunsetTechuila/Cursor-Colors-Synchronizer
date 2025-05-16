#include <Windows.h>
#include <unordered_map>

#include "CursorService.hpp"
#include "FileSystemService.hpp"
#include "RegistryService.hpp"
#include "SystemThemeService.hpp"

namespace CCS {
CursorService::CursorService(
    const std::shared_ptr<PathProvider> pathProvider,
    const std::shared_ptr<PreferencesManager> preferencesManager)
    : m_PathProvider(std::move(pathProvider)),
      m_PreferencesManager(std::move(preferencesManager)) {}

void CursorService::CopyCursors() {
  const std::filesystem::path editedCursorsFolder =
      m_PathProvider->EditedCursorsPath;
  const std::filesystem::path alternatePrecision =
      editedCursorsFolder / "precision_alt.cur";
  const std::filesystem::path defaultPrecision =
      editedCursorsFolder / "precision.cur";
  const std::filesystem::path originalCursorsFolder =
      m_PathProvider->GetOriginalCursorsFolder(m_PreferencesManager);

  if (!FileSystemService::DirectoryExists(editedCursorsFolder)) {
    FileSystemService::CreateDirectory(editedCursorsFolder);
  }

  FileSystemService::CopyFilesRecursively(originalCursorsFolder,
                                          editedCursorsFolder, true);

  if (m_PreferencesManager->useTailVersion) {
    return;
  }

  if (m_PreferencesManager->useAlternatePrecision) {
    FileSystemService::DeleteFile(defaultPrecision);
    FileSystemService::CopyFile(defaultPrecision, alternatePrecision);
    FileSystemService::RenameFile(alternatePrecision, defaultPrecision);
  } else {
    FileSystemService::DeleteFile(alternatePrecision);
  }
}

void CursorService::EditCursor(const std::filesystem::path &cursorPath,
                               const std::filesystem::path &diffPath,
                               const Color &targetColor) {
  std::vector<std::string> addresses =
      FileSystemService::ReadAllLines(diffPath);
  std::vector<uint8_t> cursor = FileSystemService::ReadAllBytes(cursorPath);

  int i = 0;
  for (const auto &addressStr : addresses) {
    i++;
    int address = std::stoi(addressStr);

    if (address >= 0 && address < cursor.size()) {
      switch (i) {
      case 1:
        cursor[address] = targetColor.B;
        break;
      case 2:
        cursor[address] = targetColor.G;
        break;
      case 3:
        cursor[address] = targetColor.R;
        i = 0;
        break;
      }
    }
  }

  FileSystemService::WriteAllBytes(cursorPath, cursor);
}

void CursorService::EditCursors() {
  const std::filesystem::path diffsFolder =
      m_PathProvider->GetDiffsFolder(m_PreferencesManager);
  const std::filesystem::path cursorsFolder = m_PathProvider->EditedCursorsPath;
  const Color accentColor = SystemThemeService::GetAccentColor();

  std::string cursorTheme = m_PreferencesManager->GetEffectiveCursorTheme();
  auto cursorSize = m_PreferencesManager->cursorSize;
  bool useTailVersion = m_PreferencesManager->useTailVersion;

  const std::filesystem::path busyCursor = cursorsFolder / "busy.ani";
  const bool shouldUseAlternateBusyDiff =
      (!useTailVersion && cursorSize == PreferencesManager::CursorSize::Big &&
       cursorTheme == "light");
  const std::filesystem::path busyCursorDiff = shouldUseAlternateBusyDiff
                                                   ? (diffsFolder / "busy_alt")
                                                   : (diffsFolder / "busy");
  const std::filesystem::path workingCursor = cursorsFolder / "working.ani";
  const std::filesystem::path workingCursorDiff = diffsFolder / "working";

  EditCursor(busyCursor, busyCursorDiff, accentColor);
  EditCursor(workingCursor, workingCursorDiff, accentColor);
}

void CursorService::SetCursor(const std::string &name,
                              const std::string &path) {
  RegistryService::SetStringValue(L"Control Panel\\Cursors",
                                  std::wstring(name.begin(), name.end()),
                                  std::wstring(path.begin(), path.end()));
}

void CursorService::InstallCursors() {
  // Map of cursor filenames to Windows cursor names
  static const std::unordered_map<std::string, std::string> knownCursors = {
      {"alternate.cur", "UpArrow"},  {"beam.cur", "IBeam"},
      {"busy.ani", "Wait"},          {"dgn1.cur", "SizeNWSE"},
      {"dgn2.cur", "SizeNESW"},      {"handwriting.cur", "NWPen"},
      {"help.cur", "Help"},          {"horz.cur", "SizeWE"},
      {"link.cur", "Hand"},          {"move.cur", "SizeAll"},
      {"person.cur", "Person"},      {"pin.cur", "Pin"},
      {"pointer.cur", "Arrow"},      {"precision.cur", "Crosshair"},
      {"unavailable.cur", "No"},     {"vert.cur", "SizeNS"},
      {"working.ani", "AppStarting"}};

  std::filesystem::path cursorsFolder = m_PathProvider->EditedCursorsPath;

  for (const auto &entry : std::filesystem::directory_iterator(cursorsFolder)) {
    if (entry.is_regular_file()) {
      std::string fileName = entry.path().filename().string();
      auto iterator = knownCursors.find(fileName);

      if (iterator != knownCursors.end()) {
        SetCursor(iterator->second, entry.path().string());
      } else {
        // Log warning about unsupported cursor
        // TODO: Add logging
      }
    }
  }

  UpdateCursorSettings();
}

void CursorService::UpdateCursorSettings() {
  SystemParametersInfoA(SPI_SETCURSORS, 0, nullptr,
                        SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
}

void CursorService::ResetToDefaultCursors() {
  auto defaultCursors = GetDefaultCursors();

  for (const auto &cursor : defaultCursors) {
    SetCursor(cursor.GetName(), cursor.GetPath());
  }

  UpdateCursorSettings();
}

std::vector<CursorInfo> CursorService::GetDefaultCursors() const {
  return {CursorInfo("AppStarting", "%SystemRoot%\\cursors\\aero_working.ani"),
          CursorInfo("Arrow", "%SystemRoot%\\cursors\\aero_arrow.cur"),
          CursorInfo("Crosshair", "%SystemRoot%\\cursors\\aero_unavail.cur"),
          CursorInfo("Hand", "%SystemRoot%\\cursors\\aero_link.cur"),
          CursorInfo("Help", "%SystemRoot%\\cursors\\aero_helpsel.cur"),
          CursorInfo("No", "%SystemRoot%\\cursors\\aero_unavail.cur"),
          CursorInfo("NWPen", "%SystemRoot%\\cursors\\aero_pen.cur"),
          CursorInfo("Person", "%SystemRoot%\\cursors\\aero_person.cur"),
          CursorInfo("Pin", "%SystemRoot%\\cursors\\aero_pin.cur"),
          CursorInfo("SizeAll", "%SystemRoot%\\cursors\\aero_move.cur"),
          CursorInfo("SizeNESW", "%SystemRoot%\\cursors\\aero_nesw.cur"),
          CursorInfo("SizeNS", "%SystemRoot%\\cursors\\aero_ns.cur"),
          CursorInfo("SizeNWSE", "%SystemRoot%\\cursors\\aero_nwse.cur"),
          CursorInfo("SizeWE", "%SystemRoot%\\cursors\\aero_ew.cur"),
          CursorInfo("UpArrow", "%SystemRoot%\\cursors\\aero_up.cur"),
          CursorInfo("Wait", "%SystemRoot%\\cursors\\aero_busy.ani")};
}

std::vector<CursorInfo> CursorService::GetEditedCursors() const {
  std::vector<CursorInfo> cursors;
  std::filesystem::path editedCursorsFolder = m_PathProvider->EditedCursorsPath;

  // Map of cursor filenames to Windows cursor names
  static const std::unordered_map<std::string, std::string> knownCursors = {
      {"alternate.cur", "UpArrow"},  {"beam.cur", "IBeam"},
      {"busy.ani", "Wait"},          {"dgn1.cur", "SizeNWSE"},
      {"dgn2.cur", "SizeNESW"},      {"handwriting.cur", "NWPen"},
      {"help.cur", "Help"},          {"horz.cur", "SizeWE"},
      {"link.cur", "Hand"},          {"move.cur", "SizeAll"},
      {"person.cur", "Person"},      {"pin.cur", "Pin"},
      {"pointer.cur", "Arrow"},      {"precision.cur", "Crosshair"},
      {"unavailable.cur", "No"},     {"vert.cur", "SizeNS"},
      {"working.ani", "AppStarting"}};

  // Get all custom cursors
  for (const auto &entry :
       std::filesystem::directory_iterator(editedCursorsFolder)) {
    if (entry.is_regular_file()) {
      std::string fileName = entry.path().filename().string();
      auto iterator = knownCursors.find(fileName);

      if (iterator != knownCursors.end()) {
        cursors.emplace_back(iterator->second, entry.path().string());
      }
    }
  }

  return cursors;
}

void CursorService::SynchronizeCursorsWithSystem() {
  CopyCursors();
  EditCursors();
  InstallCursors();
}
} // namespace CCS