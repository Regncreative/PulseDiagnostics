#include "collectors/event_log_channel_catalog.hpp"

#include "logging/logger.hpp"
#include "windows/wevt_helpers.hpp"

#include <algorithm>

namespace pulse {
namespace {

constexpr DWORD kChannelPathInitialChars = 256;

/// Reads one fixed-size channel config property; false when unavailable.
bool GetChannelConfigVariant(EVT_HANDLE config,
                             EVT_CHANNEL_CONFIG_PROPERTY_ID property,
                             EVT_VARIANT* out) {
  DWORD used = 0;
  return EvtGetChannelConfigProperty(config, property, 0, sizeof(EVT_VARIANT),
                                     out, &used) != FALSE;
}

/// Lower-cases ASCII only: channel names are ASCII in practice, and this keeps
/// the comparison locale-independent.
char AsciiLower(char c) {
  return (c >= 'A' && c <= 'Z') ? static_cast<char>(c - 'A' + 'a') : c;
}

bool ContainsPath(const std::vector<std::string>& paths, const std::string& path) {
  return std::any_of(paths.begin(), paths.end(), [&](const std::string& p) {
    return ChannelPathEquals(p, path);
  });
}

}  // namespace

ipc::EventLogChannelType ChannelTypeFromEvt(std::uint32_t evt_type) {
  switch (evt_type) {
    case EvtChannelTypeAdmin:
      return ipc::EventLogChannelType::Admin;
    case EvtChannelTypeOperational:
      return ipc::EventLogChannelType::Operational;
    case EvtChannelTypeAnalytic:
      return ipc::EventLogChannelType::Analytic;
    case EvtChannelTypeDebug:
      return ipc::EventLogChannelType::Debug;
    default:
      return ipc::EventLogChannelType::Unknown;
  }
}

ipc::EventLogChannelAccess ChannelAccessFromError(unsigned long win32_error) {
  switch (win32_error) {
    case ERROR_SUCCESS:
      return ipc::EventLogChannelAccess::Readable;
    case ERROR_ACCESS_DENIED:
      return ipc::EventLogChannelAccess::Denied;
    case ERROR_EVT_CHANNEL_NOT_FOUND:
      return ipc::EventLogChannelAccess::NotFound;
    default:
      return ipc::EventLogChannelAccess::Error;
  }
}

bool IsTrackableChannelType(ipc::EventLogChannelType type) {
  return type == ipc::EventLogChannelType::Admin ||
         type == ipc::EventLogChannelType::Operational;
}

bool ChannelPathEquals(const std::string& a, const std::string& b) {
  if (a.size() != b.size()) {
    return false;
  }
  for (std::size_t i = 0; i < a.size(); ++i) {
    if (AsciiLower(a[i]) != AsciiLower(b[i])) {
      return false;
    }
  }
  return true;
}

void SortChannelsByPath(std::vector<ipc::EventLogChannelInfo>* channels) {
  std::sort(channels->begin(), channels->end(),
            [](const ipc::EventLogChannelInfo& a,
               const ipc::EventLogChannelInfo& b) {
              return std::lexicographical_compare(
                  a.path.begin(), a.path.end(), b.path.begin(), b.path.end(),
                  [](char x, char y) { return AsciiLower(x) < AsciiLower(y); });
            });
}

bool EnumerateChannelPaths(std::vector<std::wstring>* out_paths,
                           unsigned long* out_error) {
  out_paths->clear();
  wevt::EvtHandle channel_enum(EvtOpenChannelEnum(nullptr, 0));
  if (!channel_enum) {
    if (out_error != nullptr) {
      *out_error = GetLastError();
    }
    return false;
  }

  std::wstring buffer(kChannelPathInitialChars, L'\0');
  for (;;) {
    DWORD used = 0;
    if (EvtNextChannelPath(channel_enum.get(), static_cast<DWORD>(buffer.size()),
                           buffer.data(), &used)) {
      // `used` counts the terminating null.
      out_paths->emplace_back(buffer.data(), used > 0 ? used - 1 : 0);
      continue;
    }
    const DWORD error = GetLastError();
    if (error == ERROR_NO_MORE_ITEMS) {
      break;
    }
    if (error == ERROR_INSUFFICIENT_BUFFER) {
      buffer.assign(used, L'\0');
      continue;
    }
    if (out_error != nullptr) {
      *out_error = error;
    }
    return false;
  }

  if (out_error != nullptr) {
    *out_error = ERROR_SUCCESS;
  }
  return true;
}

ipc::EventLogChannelInfo ProbeChannel(const std::wstring& path) {
  ipc::EventLogChannelInfo info;
  info.path = wevt::WideToUtf8(path);

  wevt::EvtHandle config(EvtOpenChannelConfig(nullptr, path.c_str(), 0));
  if (!config) {
    const DWORD error = GetLastError();
    info.access = ChannelAccessFromError(error);
    info.detail = wevt::FormatWin32Error(error);
    return info;
  }

  EVT_VARIANT value{};
  if (GetChannelConfigVariant(config.get(), EvtChannelConfigType, &value) &&
      value.Type == EvtVarTypeUInt32) {
    info.type = ChannelTypeFromEvt(value.UInt32Val);
  }
  value = EVT_VARIANT{};
  if (GetChannelConfigVariant(config.get(), EvtChannelConfigEnabled, &value) &&
      value.Type == EvtVarTypeBoolean) {
    info.enabled = value.BooleanVal != FALSE;
  }

  // Analytic / Debug are never tracked: skip the log probe for them.
  if (!IsTrackableChannelType(info.type)) {
    return info;
  }

  // EvtOpenLog checks the channel's read access for the calling account, so
  // under LocalService it reports the same denial EvtSubscribe would.
  wevt::EvtHandle log(EvtOpenLog(nullptr, path.c_str(), EvtOpenChannelPath));
  if (!log) {
    const DWORD error = GetLastError();
    info.access = ChannelAccessFromError(error);
    info.detail = wevt::FormatWin32Error(error);
    return info;
  }
  info.access = ipc::EventLogChannelAccess::Readable;

  value = EVT_VARIANT{};
  DWORD used = 0;
  if (EvtGetLogInfo(log.get(), EvtLogNumberOfLogRecords, sizeof(EVT_VARIANT),
                    &value, &used) &&
      value.Type == EvtVarTypeUInt64) {
    info.record_count = value.UInt64Val;
    info.has_record_count = true;
  }
  return info;
}

bool ListTrackableChannels(const std::vector<std::string>& built_in,
                           const std::vector<std::string>& tracked,
                           ChannelEnumeration* out, std::string* out_error) {
  out->channels.clear();
  out->skipped_channels = 0;

  std::vector<std::wstring> paths;
  unsigned long error = ERROR_SUCCESS;
  if (!EnumerateChannelPaths(&paths, &error)) {
    if (out_error != nullptr) {
      *out_error = "EvtOpenChannelEnum failed: " +
                   wevt::FormatWin32Error(static_cast<DWORD>(error));
    }
    Logger::Instance().Error("EventLogChannelCatalog",
                             "Channel enumeration failed: " +
                                 wevt::FormatWin32Error(static_cast<DWORD>(error)));
    return false;
  }

  out->channels.reserve(paths.size());
  std::uint32_t unreadable_config = 0;
  for (const std::wstring& path : paths) {
    ipc::EventLogChannelInfo info = ProbeChannel(path);
    if (!IsTrackableChannelType(info.type)) {
      // Unknown type means the configuration itself could not be read.
      if (info.type == ipc::EventLogChannelType::Unknown) {
        ++unreadable_config;
      }
      ++out->skipped_channels;
      continue;
    }
    info.built_in = ContainsPath(built_in, info.path);
    info.tracked = !info.built_in && ContainsPath(tracked, info.path);
    out->channels.push_back(std::move(info));
  }
  SortChannelsByPath(&out->channels);

  Logger::Instance().Info(
      "EventLogChannelCatalog",
      "Listed channels=" + std::to_string(out->channels.size()) +
          " skipped=" + std::to_string(out->skipped_channels) +
          " unreadable_config=" + std::to_string(unreadable_config));
  return true;
}

}  // namespace pulse
