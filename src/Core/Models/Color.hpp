#pragma once

#include <cstdint>
#include <optional>
#include <string>

namespace CCS {
class Color {
public:
  Color(uint8_t r, uint8_t g, uint8_t b);

  const uint8_t R;
  const uint8_t G;
  const uint8_t B;

  std::string ToHex() const;

  bool operator==(const Color &other) const;
  bool operator!=(const Color &other) const;
};
} // namespace CCS