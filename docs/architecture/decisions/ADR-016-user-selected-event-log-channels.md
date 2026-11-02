# ADR-016: User-selected Event Log channels

**Status:** **Proposed** (2026-11-02)

**Date:** 2026-11-02

---

## Context

The Timeline reads a fixed set of channels (`collectors/event_log_channels.cpp`): System, Application, Setup, WindowsUpdateClient/Operational, Kernel-PnP/Configuration, Kernel-Power/Thermal-Operational, Kernel-Boot/Operational and Security when readable. Users asked to follow other channels (for example `Microsoft-Windows-TaskScheduler/Operational`), pin the ones they open most and filter the Timeline to one channel.

Constraints:

- AGENTS.md: read-only. Pulse never enables, disables, clears or reconfigures a channel.
- PulseService runs as **LocalService**. Some channels deny it read access; that must be shown, not hidden.
- ADR-007: Event Log stays the only Timeline source. This ADR only widens which channels are read.
- ADR-008: live delivery stays on the per-connection queues; more channels must not stall ingest.

## Decision

1. **Enumeration.** `ListEventLogChannels` returns every channel from `EvtOpenChannelEnum` / `EvtNextChannelPath` whose type (`EvtGetChannelConfigProperty(EvtChannelConfigType)`) is Admin or Operational. For each one it returns:
   - its enabled state (`EvtChannelConfigEnabled`);
   - its record count (`EvtOpenLog` + `EvtGetLogInfo(EvtLogNumberOfLogRecords)`);
   - whether the service can read it (`EvtQuery` probe);
   - whether it is built in or tracked.

   Analytic and Debug channels are never listed or tracked. They are high-volume tracing channels, disabled by default. Using them would mean turning them on, and Pulse never makes that configuration change.
2. **Tracked list.** The service owns it and persists it in `%ProgramData%\Pulse\tracked_channels.json` (`{"version":1,"channels":[...]}`). The file is written to a temp file and then renamed. LocalService has full control of `%ProgramData%\Pulse`.
3. **Updating it.** `SetTrackedChannels` carries the **full** list and is idempotent. The service validates each entry, then diffs it against the running subscriptions: it starts subscriptions for added channels and stops them for removed ones, without a restart. The reply gives each requested channel's status:
   - accepted: tracked, or disabled (no events until the user enables the channel);
   - rejected: access denied, not found, unsupported type, over limit;
   - already built in.

   Only accepted channels are persisted.
4. **Cap.** At most **16** tracked channels (`kMaxTrackedChannels`) on top of the built-in set. An idle subscription costs almost nothing. The cost comes from busy channels: each event is rendered and its message formatted. The snapshot budget is also shared by every channel.
5. **Snapshot.** The Timeline snapshot reads the built-in channels plus the tracked ones, with the existing fair per-channel share.
6. **App.** A *Manage channels* screen lists the channels with search, check boxes and visible states. For a disabled channel it shows the command `wevtutil sl <channel> /e:true` for the user to run. Pulse never runs it. Favorites stay app-local (SharedPreferences). The Timeline gets a channel filter: one channel, or all of them merged.
7. **Unknown events.** Events without a catalog rule are titled `<provider> · Event <id>` and keep the first line of the raw message as summary.

## Consequences

- New: `collectors/event_log_channel_catalog`, `collectors/live_channel_subscriptions`, `collectors/tracked_channels_store`, wire messages 41–44, the app's `ChannelsController` and *Manage channels* screen.
- The list is per machine, not per Windows user.
- Protocol version stays 1: messages are additive. An older service answers the new requests with "unknown message", and the app then reports that the service must be updated.

## Limitations and future work

- A channel disabled when it was subscribed is subscribed again when the user next opens *Manage channels* or saves the list. Pulse does not watch channel configuration.
- Listing every channel takes a moment (around a thousand channels on Windows 11). It runs only when *Manage channels* opens.
- Custom views, per-channel retention and channel-specific explanations are out of scope.

## References

- [EvtOpenChannelEnum](https://learn.microsoft.com/windows/win32/api/winevt/nf-winevt-evtopenchannelenum), [EvtNextChannelPath](https://learn.microsoft.com/windows/win32/api/winevt/nf-winevt-evtnextchannelpath)
- [EvtGetChannelConfigProperty](https://learn.microsoft.com/windows/win32/api/winevt/nf-winevt-evtgetchannelconfigproperty), [EVT_CHANNEL_TYPE](https://learn.microsoft.com/windows/win32/api/winevt/ne-winevt-evt_channel_type)
- [EvtGetLogInfo](https://learn.microsoft.com/windows/win32/api/winevt/nf-winevt-evtgetloginfo)
- [ADR-007](ADR-007-event-log-only-v1.md), [ADR-008](ADR-008-hot-cold-live-queues.md)
