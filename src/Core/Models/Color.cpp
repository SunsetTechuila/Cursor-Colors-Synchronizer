#include <iomanip>
#include <sstream>

#include "Color.hpp"

namespace CCS {
Color::Color(uint8_t r, uint8_t g, uint8_t b) : R(r), G(g), B(b) {}

std::string Color::ToHex() const {
  std::stringstream stringStream;
  stringStream << "#" << std::hex << std::setfill('0') << std::setw(2)
               << static_cast<int>(R) << std::hex << std::setfill('0')
               << std::setw(2) << static_cast<int>(G) << std::hex
               << std::setfill('0') << std::setw(2) << static_cast<int>(B);
  return stringStream.str();
}

bool Color::operator==(const Color &other) const {
  return R == other.R && G == other.G && B == other.B;
}

bool Color::operator!=(const Color &other) const { return !(*this == other); }
} // namespace CCS