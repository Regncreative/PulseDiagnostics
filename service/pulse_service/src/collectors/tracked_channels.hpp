#pragma once

#include "pulse_wire.hpp"

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

namespace pulse {

/// Channels the user follows on top of the built-in set (ADR-016).
constexpr std::uint32_t kMaxTrackedChannels = 16;

/// Reads one channel's state (normally ProbeChannel); injectable for tests.
using ChannelProber =
    std::function<ipc::EventLogChannelInfo(const std::string& path)>;

/// Validates a requested tracked list.
/// - Duplicates (case-insensitive) and empty names are dropped.
/// - Built-in channels are answered BuiltIn and not stored.
/// - Analytic / Debug, missing and unreadable channels are rejected.
/// - Accepted channels beyond `max_tracked` are rejected OverLimit.
/// `out->tracked` is the list to save and subscribe, in request order.
void ValidateTrackedChannels(const std::vector<std::string>& requested,
                             const std::vector<std::string>& built_in,
                             const ChannelProber& probe,
                             std::uint32_t max_tracked,
                             ipc::TrackedChannels* out);

/// `{"version":1,"channels":[...]}` with JSON string escaping.
[[nodiscard]] std::string SerializeTrackedChannels(
    const std::vector<std::string>& channels);

/// Parses SerializeTrackedChannels output. Returns false on malformed input.
[[nodiscard]] bool ParseTrackedChannels(const std::string& json,
                                        std::vector<std::string>* out,
                                        std::string* out_error);

/// Loads / saves the list in one JSON file (%ProgramData%\Pulse\tracked_channels.json).
class TrackedChannelsStore {
 public:
  explicit TrackedChannelsStore(std::wstring path);

  /// A missing file is an empty list, not an error.
  [[nodiscard]] bool Load(std::vector<std::string>* out,
                          std::string* out_error) const;

  /// Writes a temp file next to the target, then replaces the target.
  [[nodiscard]] bool Save(const std::vector<std::string>& channels,
                          std::string* out_error) const;

  [[nodiscard]] const std::wstring& path() const noexcept { return path_; }

 private:
  std::wstring path_;
};

}  // namespace pulse
