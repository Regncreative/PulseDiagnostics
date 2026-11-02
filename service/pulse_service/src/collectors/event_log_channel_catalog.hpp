#pragma once

#include "pulse_wire.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace pulse {

/// Every channel registered on this PC, read with Wevtapi (ADR-016).
/// Read-only: channels are opened for their configuration and record count,
/// never reconfigured or cleared.

/// EVT_CHANNEL_TYPE (Admin 0 … Debug 3) → wire type (+1, 0 = unknown).
[[nodiscard]] ipc::EventLogChannelType ChannelTypeFromEvt(std::uint32_t evt_type);

/// Win32 error from EvtOpenChannelConfig / EvtOpenLog → wire access state.
[[nodiscard]] ipc::EventLogChannelAccess ChannelAccessFromError(
    unsigned long win32_error);

/// Admin and Operational channels can be tracked; Analytic and Debug cannot.
[[nodiscard]] bool IsTrackableChannelType(ipc::EventLogChannelType type);

/// Windows channel names are case-insensitive.
[[nodiscard]] bool ChannelPathEquals(const std::string& a, const std::string& b);

/// Sorts by path, case-insensitive (the order the app lists them in).
void SortChannelsByPath(std::vector<ipc::EventLogChannelInfo>* channels);

/// All channel paths from EvtOpenChannelEnum / EvtNextChannelPath.
/// Returns false (and the Win32 error) when enumeration cannot start.
[[nodiscard]] bool EnumerateChannelPaths(std::vector<std::wstring>* out_paths,
                                         unsigned long* out_error);

/// Type, enabled state, record count and access for one channel.
/// `access` is NotFound when the channel is not registered.
[[nodiscard]] ipc::EventLogChannelInfo ProbeChannel(const std::wstring& path);

struct ChannelEnumeration {
  std::vector<ipc::EventLogChannelInfo> channels;  // trackable types, sorted
  std::uint32_t skipped_channels = 0;               // Analytic / Debug
};

/// Enumerates and probes every channel, keeping Admin / Operational only.
/// `built_in` and `tracked` mark the matching entries.
[[nodiscard]] bool ListTrackableChannels(const std::vector<std::string>& built_in,
                                         const std::vector<std::string>& tracked,
                                         ChannelEnumeration* out,
                                         std::string* out_error);

}  // namespace pulse
