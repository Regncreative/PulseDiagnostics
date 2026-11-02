#include "collectors/tracked_channels.hpp"

#include "collectors/event_log_channel_catalog.hpp"

#include <algorithm>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <sstream>

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>

namespace pulse {
namespace {

constexpr int kTrackedChannelsFileVersion = 1;

bool ContainsPath(const std::vector<std::string>& paths, const std::string& path) {
  return std::any_of(paths.begin(), paths.end(), [&](const std::string& p) {
    return ChannelPathEquals(p, path);
  });
}

std::string Trim(const std::string& value) {
  const auto first = value.find_first_not_of(" \t\r\n");
  if (first == std::string::npos) {
    return {};
  }
  const auto last = value.find_last_not_of(" \t\r\n");
  return value.substr(first, last - first + 1);
}

ipc::TrackedChannelStatus StatusForProbe(const ipc::EventLogChannelInfo& info) {
  if (info.access == ipc::EventLogChannelAccess::NotFound) {
    return ipc::TrackedChannelStatus::NotFound;
  }
  // ProbeChannel never opens Analytic / Debug logs, so their access is unknown:
  // decide on the type first.
  if (info.type == ipc::EventLogChannelType::Analytic ||
      info.type == ipc::EventLogChannelType::Debug) {
    return ipc::TrackedChannelStatus::UnsupportedType;
  }
  switch (info.access) {
    case ipc::EventLogChannelAccess::Denied:
      return ipc::TrackedChannelStatus::AccessDenied;
    case ipc::EventLogChannelAccess::Readable:
      break;
    default:
      return ipc::TrackedChannelStatus::Failed;
  }
  if (!IsTrackableChannelType(info.type)) {
    return ipc::TrackedChannelStatus::UnsupportedType;
  }
  return info.enabled ? ipc::TrackedChannelStatus::Tracked
                      : ipc::TrackedChannelStatus::Disabled;
}

void AppendJsonString(const std::string& value, std::string* out) {
  out->push_back('"');
  for (const char c : value) {
    switch (c) {
      case '"':
        *out += "\\\"";
        break;
      case '\\':
        *out += "\\\\";
        break;
      case '\n':
        *out += "\\n";
        break;
      case '\r':
        *out += "\\r";
        break;
      case '\t':
        *out += "\\t";
        break;
      default:
        if (static_cast<unsigned char>(c) < 0x20) {
          char buf[8];
          std::snprintf(buf, sizeof(buf), "\\u%04x", static_cast<unsigned>(c));
          *out += buf;
        } else {
          out->push_back(c);  // UTF-8 bytes pass through
        }
    }
  }
  out->push_back('"');
}

void AppendUtf8(std::uint32_t code_point, std::string* out) {
  if (code_point < 0x80) {
    out->push_back(static_cast<char>(code_point));
  } else if (code_point < 0x800) {
    out->push_back(static_cast<char>(0xC0 | (code_point >> 6)));
    out->push_back(static_cast<char>(0x80 | (code_point & 0x3F)));
  } else {
    out->push_back(static_cast<char>(0xE0 | (code_point >> 12)));
    out->push_back(static_cast<char>(0x80 | ((code_point >> 6) & 0x3F)));
    out->push_back(static_cast<char>(0x80 | (code_point & 0x3F)));
  }
}

/// Reads one JSON string starting at the opening quote; advances `pos` past it.
bool ReadJsonString(const std::string& json, std::size_t* pos, std::string* out) {
  if (*pos >= json.size() || json[*pos] != '"') return false;
  ++*pos;
  out->clear();
  while (*pos < json.size()) {
    const char c = json[(*pos)++];
    if (c == '"') return true;
    if (c != '\\') {
      out->push_back(c);
      continue;
    }
    if (*pos >= json.size()) return false;
    const char e = json[(*pos)++];
    switch (e) {
      case '"': out->push_back('"'); break;
      case '\\': out->push_back('\\'); break;
      case '/': out->push_back('/'); break;
      case 'b': out->push_back('\b'); break;
      case 'f': out->push_back('\f'); break;
      case 'n': out->push_back('\n'); break;
      case 'r': out->push_back('\r'); break;
      case 't': out->push_back('\t'); break;
      case 'u': {
        if (*pos + 4 > json.size()) return false;
        std::uint32_t code_point = 0;
        for (int i = 0; i < 4; ++i) {
          const char h = json[(*pos)++];
          code_point <<= 4;
          if (h >= '0' && h <= '9') code_point |= h - '0';
          else if (h >= 'a' && h <= 'f') code_point |= h - 'a' + 10;
          else if (h >= 'A' && h <= 'F') code_point |= h - 'A' + 10;
          else return false;
        }
        AppendUtf8(code_point, out);
        break;
      }
      default:
        return false;
    }
  }
  return false;  // unterminated
}

void SkipWhitespace(const std::string& json, std::size_t* pos) {
  while (*pos < json.size() &&
         (json[*pos] == ' ' || json[*pos] == '\t' || json[*pos] == '\r' ||
          json[*pos] == '\n')) {
    ++*pos;
  }
}

}  // namespace

void ValidateTrackedChannels(const std::vector<std::string>& requested,
                             const std::vector<std::string>& built_in,
                             const ChannelProber& probe,
                             std::uint32_t max_tracked,
                             ipc::TrackedChannels* out) {
  out->results.clear();
  out->tracked.clear();
  out->max_tracked = max_tracked;

  std::vector<std::string> seen;
  for (const std::string& raw : requested) {
    const std::string path = Trim(raw);
    if (path.empty() || ContainsPath(seen, path)) {
      continue;
    }
    seen.push_back(path);

    ipc::TrackedChannelResult result;
    result.path = path;
    if (ContainsPath(built_in, path)) {
      result.status = ipc::TrackedChannelStatus::BuiltIn;
      out->results.push_back(std::move(result));
      continue;
    }

    const ipc::EventLogChannelInfo info = probe(path);
    result.status = StatusForProbe(info);
    result.detail = info.detail;
    const bool accepted = result.status == ipc::TrackedChannelStatus::Tracked ||
                          result.status == ipc::TrackedChannelStatus::Disabled;
    if (accepted && out->tracked.size() >= max_tracked) {
      result.status = ipc::TrackedChannelStatus::OverLimit;
      result.detail = "At most " + std::to_string(max_tracked) +
                      " channels can be added.";
    } else if (accepted) {
      // Keep Windows' spelling of the name when the probe resolved it.
      out->tracked.push_back(info.path.empty() ? path : info.path);
    }
    out->results.push_back(std::move(result));
  }
}

std::string SerializeTrackedChannels(const std::vector<std::string>& channels) {
  std::string out = "{\n  \"version\": " +
                    std::to_string(kTrackedChannelsFileVersion) +
                    ",\n  \"channels\": [";
  for (std::size_t i = 0; i < channels.size(); ++i) {
    out += i == 0 ? "\n    " : ",\n    ";
    AppendJsonString(channels[i], &out);
  }
  out += channels.empty() ? "]\n}\n" : "\n  ]\n}\n";
  return out;
}

bool ParseTrackedChannels(const std::string& json, std::vector<std::string>* out,
                          std::string* out_error) {
  out->clear();
  const std::size_t key = json.find("\"channels\"");
  if (key == std::string::npos) {
    if (out_error != nullptr) *out_error = "missing \"channels\"";
    return false;
  }
  std::size_t pos = key + std::string("\"channels\"").size();
  SkipWhitespace(json, &pos);
  if (pos >= json.size() || json[pos] != ':') {
    if (out_error != nullptr) *out_error = "expected ':' after \"channels\"";
    return false;
  }
  ++pos;
  SkipWhitespace(json, &pos);
  if (pos >= json.size() || json[pos] != '[') {
    if (out_error != nullptr) *out_error = "\"channels\" is not an array";
    return false;
  }
  ++pos;
  SkipWhitespace(json, &pos);
  if (pos < json.size() && json[pos] == ']') {
    return true;
  }
  for (;;) {
    std::string value;
    if (!ReadJsonString(json, &pos, &value)) {
      if (out_error != nullptr) *out_error = "invalid string in \"channels\"";
      out->clear();
      return false;
    }
    out->push_back(std::move(value));
    SkipWhitespace(json, &pos);
    if (pos < json.size() && json[pos] == ',') {
      ++pos;
      SkipWhitespace(json, &pos);
      continue;
    }
    if (pos < json.size() && json[pos] == ']') {
      return true;
    }
    if (out_error != nullptr) *out_error = "unterminated \"channels\" array";
    out->clear();
    return false;
  }
}

TrackedChannelsStore::TrackedChannelsStore(std::wstring path)
    : path_(std::move(path)) {}

bool TrackedChannelsStore::Load(std::vector<std::string>* out,
                                std::string* out_error) const {
  out->clear();
  std::error_code ec;
  if (!std::filesystem::exists(path_, ec)) {
    return true;
  }
  std::ifstream file(std::filesystem::path(path_), std::ios::binary);
  if (!file) {
    if (out_error != nullptr) *out_error = "cannot open tracked channels file";
    return false;
  }
  std::ostringstream content;
  content << file.rdbuf();
  return ParseTrackedChannels(content.str(), out, out_error);
}

bool TrackedChannelsStore::Save(const std::vector<std::string>& channels,
                                std::string* out_error) const {
  const std::filesystem::path target(path_);
  std::error_code ec;
  std::filesystem::create_directories(target.parent_path(), ec);

  const std::filesystem::path temp = target.wstring() + L".tmp";
  {
    std::ofstream file(temp, std::ios::binary | std::ios::trunc);
    if (!file) {
      if (out_error != nullptr) *out_error = "cannot write tracked channels file";
      return false;
    }
    file << SerializeTrackedChannels(channels);
    if (!file.good()) {
      if (out_error != nullptr) *out_error = "write to tracked channels file failed";
      return false;
    }
  }
  if (!MoveFileExW(temp.c_str(), target.c_str(),
                   MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
    const DWORD error = GetLastError();
    std::filesystem::remove(temp, ec);
    if (out_error != nullptr) {
      *out_error = "replacing tracked channels file failed (Win32 " +
                   std::to_string(error) + ")";
    }
    return false;
  }
  return true;
}

}  // namespace pulse
