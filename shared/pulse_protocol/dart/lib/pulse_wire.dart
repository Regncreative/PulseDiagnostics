/// Minimal protobuf wire codec for pulse.ipc.Envelope (matches C++ pulse_wire).

import 'dart:convert';
import 'dart:typed_data';

class ClientHello {
  ClientHello({
    this.protocolVersion = 1,
    this.clientName = '',
    this.clientVersion = '',
  });
  int protocolVersion;
  String clientName;
  String clientVersion;
}

class ServerHello {
  ServerHello({this.protocolVersion = 1, this.serviceVersion = ''});
  int protocolVersion;
  String serviceVersion;
}

class Ping {
  Ping({this.nonce = 0, this.unixMs = 0});
  int nonce;
  int unixMs;
}

class Pong {
  Pong({this.nonce = 0, this.unixMs = 0, this.serviceVersion = ''});
  int nonce;
  int unixMs;
  String serviceVersion;
}

class Heartbeat {
  Heartbeat({this.unixMs = 0});
  int unixMs;
}

class ErrorResponse {
  ErrorResponse({
    this.code = 0,
    this.message = '',
    this.technicalDetail = '',
    this.component = '',
  });
  int code;
  String message;
  String technicalDetail;
  String component;
}

/// Matches pulse.ipc.Severity / C++ Severity.
class Severity {
  static const int unknown = 0;
  static const int info = 1;
  static const int warning = 2;
  static const int error = 3;
  static const int critical = 4;
  static const int verbose = 5;
}

/// Matches pulse.ipc.Importance / C++ Importance.
class Importance {
  static const int low = 0;
  static const int medium = 1;
  static const int high = 2;
  static const int critical = 3;
}

class TimelineEvent {
  TimelineEvent({
    this.eventId = '',
    this.timestampUnixMs = 0,
    this.timestampIso = '',
    this.severity = Severity.unknown,
    this.channel = '',
    this.providerName = '',
    this.winEventId = 0,
    this.recordId = 0,
    this.computerName = '',
    this.summary = '',
    this.technicalSummary = '',
    this.message = '',
    this.title = '',
    this.recommendation = '',
    this.actionRequired = false,
    this.importance = Importance.low,
    this.category = '',
    this.task = 0,
    this.hasTask = false,
    this.opcode = 0,
    this.hasOpcode = false,
    this.keywords = 0,
    this.hasKeywords = false,
    this.processId = 0,
    this.hasProcessId = false,
    this.processName = '',
    this.threadId = 0,
    this.hasThreadId = false,
    this.userSid = '',
    this.activityId = '',
    this.relatedActivityId = '',
    this.levelName = '',
    this.rawXml = '',
  });
  String eventId;
  int timestampUnixMs;
  String timestampIso;
  int severity;
  String channel;
  String providerName;
  int winEventId;
  int recordId;
  String computerName;
  String summary;
  String technicalSummary;
  String message;
  String title;
  String recommendation;
  bool actionRequired;
  int importance;
  String category;
  int task;
  bool hasTask;
  int opcode;
  bool hasOpcode;
  int keywords;
  bool hasKeywords;
  int processId;
  bool hasProcessId;
  String processName;
  int threadId;
  bool hasThreadId;
  String userSid;
  String activityId;
  String relatedActivityId;
  String levelName;
  String rawXml;
}

class GetTimelineEventDetail {
  GetTimelineEventDetail({this.channel = '', this.recordId = 0});
  String channel;
  int recordId;
}

class TimelineEventDetail {
  TimelineEventDetail({this.found = false, TimelineEvent? event})
      : event = event ?? TimelineEvent();
  bool found;
  TimelineEvent event;
}

/// R3 Inventory Engine (ADR-011) — system description catalogs (not live Health).
enum InventoryDomainId {
  unspecified,
  services,
  drivers,
  software,
  usb,
  pci,
  displays,
  audio,
  bluetooth,
  printers,
  battery,
  motherboard,
  bios,
  cpu,
  memoryModules,
  storage,
  networkAdapters,
}

enum InventoryStatus {
  unspecified,
  available,
  unsupported,
  accessDenied,
  partial,
  error,
}

class InventoryServiceEntry {
  InventoryServiceEntry({
    this.id = '',
    this.displayName = '',
    this.state = '',
    this.startType = '',
    this.account = '',
    this.binaryPath = '',
    this.description = '',
  });
  String id;
  String displayName;
  String state;
  String startType;
  String account;
  String binaryPath;
  String description;
}

class InventoryDriverEntry {
  InventoryDriverEntry({
    this.id = '',
    this.displayName = '',
    this.state = '',
    this.startType = '',
    this.binaryPath = '',
    this.description = '',
    this.driverType = '',
  });
  String id;
  String displayName;
  String state;
  String startType;
  String binaryPath;
  String description;
  String driverType;
}

class InventorySoftwareEntry {
  InventorySoftwareEntry({
    this.id = '',
    this.displayName = '',
    this.version = '',
    this.publisher = '',
    this.installDate = '',
    this.installLocation = '',
    this.estimatedSizeBytes = 0,
    this.hasEstimatedSize = false,
    this.systemComponent = false,
    this.architecture = '',
  });
  String id;
  String displayName;
  String version;
  String publisher;
  String installDate;
  String installLocation;
  int estimatedSizeBytes;
  bool hasEstimatedSize;
  bool systemComponent;
  String architecture;
}

class InventoryUsbEntry {
  InventoryUsbEntry({
    this.id = '',
    this.description = '',
    this.hardwareId = '',
    this.manufacturer = '',
    this.service = '',
    this.className = '',
    this.classGuid = '',
    this.problemCode = 0,
    this.hasProblemCode = false,
  });
  String id;
  String description;
  String hardwareId;
  String manufacturer;
  String service;
  String className;
  String classGuid;
  int problemCode;
  bool hasProblemCode;
}

class InventoryPciEntry {
  InventoryPciEntry({
    this.id = '',
    this.description = '',
    this.hardwareId = '',
    this.manufacturer = '',
    this.service = '',
    this.className = '',
    this.classGuid = '',
    this.locationInfo = '',
    this.problemCode = 0,
    this.hasProblemCode = false,
  });
  String id;
  String description;
  String hardwareId;
  String manufacturer;
  String service;
  String className;
  String classGuid;
  String locationInfo;
  int problemCode;
  bool hasProblemCode;
}

class InventoryPnPDeviceEntry {
  InventoryPnPDeviceEntry({
    this.id = '',
    this.description = '',
    this.hardwareId = '',
    this.manufacturer = '',
    this.service = '',
    this.className = '',
    this.classGuid = '',
    this.locationInfo = '',
    this.problemCode = 0,
    this.hasProblemCode = false,
    this.adapterName = '',
    this.descriptionFromEnumDisplay = false,
  });
  String id;
  String description;
  String hardwareId;
  String manufacturer;
  String service;
  String className;
  String classGuid;
  String locationInfo;
  int problemCode;
  bool hasProblemCode;
  String adapterName;
  bool descriptionFromEnumDisplay;
}

class InventoryPrinterEntry {
  InventoryPrinterEntry({
    this.id = '',
    this.portName = '',
    this.driverName = '',
    this.location = '',
    this.comment = '',
    this.isShared = false,
    this.isDefault = false,
    this.isNetwork = false,
    this.attributes = 0,
    this.hasAttributes = false,
  });
  String id;
  String portName;
  String driverName;
  String location;
  String comment;
  bool isShared;
  bool isDefault;
  bool isNetwork;
  int attributes;
  bool hasAttributes;
}

class InventoryBatteryEntry {
  InventoryBatteryEntry({
    this.id = '',
    this.description = '',
    this.manufacturer = '',
    this.chemistry = '',
    this.designCapacityMwh = 0,
    this.hasDesignCapacity = false,
    this.fullChargedCapacityMwh = 0,
    this.hasFullChargedCapacity = false,
    this.cycleCount = 0,
    this.hasCycleCount = false,
    this.capacityPercent = 0,
    this.hasCapacityPercent = false,
    this.powerState = '',
    this.fromSystemPowerFallback = false,
  });
  String id;
  String description;
  String manufacturer;
  String chemistry;
  int designCapacityMwh;
  bool hasDesignCapacity;
  int fullChargedCapacityMwh;
  bool hasFullChargedCapacity;
  int cycleCount;
  bool hasCycleCount;
  int capacityPercent;
  bool hasCapacityPercent;
  String powerState;
  bool fromSystemPowerFallback;
}

class InventoryMotherboardEntry {
  InventoryMotherboardEntry({
    this.id = '',
    this.manufacturer = '',
    this.product = '',
    this.version = '',
    this.serialNumber = '',
    this.assetTag = '',
    this.locationInChassis = '',
    this.boardType = '',
  });
  String id;
  String manufacturer;
  String product;
  String version;
  String serialNumber;
  String assetTag;
  String locationInChassis;
  String boardType;
}

class InventoryBiosEntry {
  InventoryBiosEntry({
    this.id = '',
    this.vendor = '',
    this.version = '',
    this.releaseDate = '',
    this.majorRelease = 0,
    this.hasMajorRelease = false,
    this.minorRelease = 0,
    this.hasMinorRelease = false,
    this.romSizeBytes = 0,
    this.hasRomSizeBytes = false,
    this.uefiCapable = false,
    this.hasUefiCapable = false,
  });
  String id;
  String vendor;
  String version;
  String releaseDate;
  int majorRelease;
  bool hasMajorRelease;
  int minorRelease;
  bool hasMinorRelease;
  int romSizeBytes;
  bool hasRomSizeBytes;
  bool uefiCapable;
  bool hasUefiCapable;
}

class InventoryCpuEntry {
  InventoryCpuEntry({
    this.id = '',
    this.name = '',
    this.manufacturer = '',
    this.architecture = '',
    this.sockets = 0,
    this.hasSockets = false,
    this.physicalCores = 0,
    this.hasPhysicalCores = false,
    this.logicalProcessors = 0,
    this.hasLogicalProcessors = false,
    this.baseClockMhz = 0,
    this.hasBaseClockMhz = false,
    this.numaNodes = 0,
    this.hasNumaNodes = false,
    this.l1CacheBytes = 0,
    this.hasL1CacheBytes = false,
    this.l2CacheBytes = 0,
    this.hasL2CacheBytes = false,
    this.l3CacheBytes = 0,
    this.hasL3CacheBytes = false,
    this.instructionSet = '',
    this.smtEnabled = false,
    this.hasSmtEnabled = false,
    this.virtualizationVendor = '',
  });
  String id;
  String name;
  String manufacturer;
  String architecture;
  int sockets;
  bool hasSockets;
  int physicalCores;
  bool hasPhysicalCores;
  int logicalProcessors;
  bool hasLogicalProcessors;
  int baseClockMhz;
  bool hasBaseClockMhz;
  int numaNodes;
  bool hasNumaNodes;
  int l1CacheBytes;
  bool hasL1CacheBytes;
  int l2CacheBytes;
  bool hasL2CacheBytes;
  int l3CacheBytes;
  bool hasL3CacheBytes;
  String instructionSet;
  bool smtEnabled;
  bool hasSmtEnabled;
  String virtualizationVendor;
}

class InventoryMemoryModuleEntry {
  InventoryMemoryModuleEntry({
    this.id = '',
    this.bankLocator = '',
    this.manufacturer = '',
    this.partNumber = '',
    this.serialNumber = '',
    this.sizeBytes = 0,
    this.hasSizeBytes = false,
    this.speedMts = 0,
    this.hasSpeedMts = false,
    this.configuredSpeedMts = 0,
    this.hasConfiguredSpeedMts = false,
    this.formFactor = '',
    this.memoryType = '',
    this.isEcc = false,
    this.hasIsEcc = false,
    this.totalWidthBits = 0,
    this.hasTotalWidthBits = false,
    this.dataWidthBits = 0,
    this.hasDataWidthBits = false,
    this.configuredVoltageMv = 0,
    this.hasConfiguredVoltageMv = false,
    this.populated = false,
  });
  String id;
  String bankLocator;
  String manufacturer;
  String partNumber;
  String serialNumber;
  int sizeBytes;
  bool hasSizeBytes;
  int speedMts;
  bool hasSpeedMts;
  int configuredSpeedMts;
  bool hasConfiguredSpeedMts;
  String formFactor;
  String memoryType;
  bool isEcc;
  bool hasIsEcc;
  int totalWidthBits;
  bool hasTotalWidthBits;
  int dataWidthBits;
  bool hasDataWidthBits;
  int configuredVoltageMv;
  bool hasConfiguredVoltageMv;
  bool populated;
}

class InventoryStorageEntry {
  InventoryStorageEntry({
    this.id = '',
    this.devicePath = '',
    this.physicalDriveNumber = 0,
    this.hasPhysicalDriveNumber = false,
    this.model = '',
    this.vendor = '',
    this.serialNumber = '',
    this.firmwareRevision = '',
    this.busType = '',
    this.mediaType = '',
    this.sizeBytes = 0,
    this.hasSizeBytes = false,
    this.sectorSizeBytes = 0,
    this.hasSectorSizeBytes = false,
    this.partitionStyle = '',
    this.isRemovable = false,
    this.hasIsRemovable = false,
    this.trimSupported = false,
    this.hasTrimSupported = false,
    this.manufacturer = '',
    this.description = '',
  });
  String id;
  String devicePath;
  int physicalDriveNumber;
  bool hasPhysicalDriveNumber;
  String model;
  String vendor;
  String serialNumber;
  String firmwareRevision;
  String busType;
  String mediaType;
  int sizeBytes;
  bool hasSizeBytes;
  int sectorSizeBytes;
  bool hasSectorSizeBytes;
  String partitionStyle;
  bool isRemovable;
  bool hasIsRemovable;
  bool trimSupported;
  bool hasTrimSupported;
  String manufacturer;
  String description;
}

class InventoryNetworkAdapterEntry {
  InventoryNetworkAdapterEntry({
    this.id = '',
    this.description = '',
    this.friendlyName = '',
    this.macAddress = '',
    this.connectionType = '',
    this.ifIndex = 0,
    this.hasIfIndex = false,
    this.mtu = 0,
    this.hasMtu = false,
    this.operationalStatus = '',
    this.dhcpEnabled = false,
    this.hasDhcpEnabled = false,
    this.linkSpeedBps = 0,
    this.hasLinkSpeedBps = false,
    this.isLoopback = false,
    List<String>? ipv4Addresses,
    List<String>? ipv6Addresses,
    List<String>? gatewayAddresses,
    List<String>? dnsAddresses,
    this.driverProvider = '',
    this.driverVersion = '',
    this.driverDate = '',
  })  : ipv4Addresses = ipv4Addresses ?? <String>[],
        ipv6Addresses = ipv6Addresses ?? <String>[],
        gatewayAddresses = gatewayAddresses ?? <String>[],
        dnsAddresses = dnsAddresses ?? <String>[];
  String id;
  String description;
  String friendlyName;
  String macAddress;
  String connectionType;
  int ifIndex;
  bool hasIfIndex;
  int mtu;
  bool hasMtu;
  String operationalStatus;
  bool dhcpEnabled;
  bool hasDhcpEnabled;
  int linkSpeedBps;
  bool hasLinkSpeedBps;
  bool isLoopback;
  List<String> ipv4Addresses;
  List<String> ipv6Addresses;
  List<String> gatewayAddresses;
  List<String> dnsAddresses;
  String driverProvider;
  String driverVersion;
  String driverDate;
}

class GetInventoryDomain {
  GetInventoryDomain({
    this.domain = InventoryDomainId.unspecified,
    this.forceRefresh = false,
    this.sinceGeneration = 0,
    this.limit = 0,
  });
  InventoryDomainId domain;
  bool forceRefresh;
  int sinceGeneration;
  int limit;
}

class InventoryDomainSnapshot {
  InventoryDomainSnapshot({
    this.domain = InventoryDomainId.unspecified,
    this.status = InventoryStatus.unspecified,
    this.statusDetail = '',
    this.truncated = false,
    this.generation = 0,
    this.generatedAtUnixMs = 0,
    this.fullResync = true,
    this.cacheTtlMs = 0,
    List<InventoryServiceEntry>? services,
    List<InventoryDriverEntry>? drivers,
    List<InventorySoftwareEntry>? software,
    List<InventoryUsbEntry>? usb,
    List<InventoryPciEntry>? pci,
    List<InventoryPnPDeviceEntry>? displays,
    List<InventoryPnPDeviceEntry>? audio,
    List<InventoryPnPDeviceEntry>? bluetooth,
    List<InventoryPrinterEntry>? printers,
    List<InventoryBatteryEntry>? batteries,
    List<InventoryMotherboardEntry>? motherboard,
    List<InventoryBiosEntry>? bios,
    List<InventoryCpuEntry>? cpu,
    List<InventoryMemoryModuleEntry>? memoryModules,
    List<InventoryStorageEntry>? storage,
    List<InventoryNetworkAdapterEntry>? networkAdapters,
  })  : services = services ?? <InventoryServiceEntry>[],
        drivers = drivers ?? <InventoryDriverEntry>[],
        software = software ?? <InventorySoftwareEntry>[],
        usb = usb ?? <InventoryUsbEntry>[],
        pci = pci ?? <InventoryPciEntry>[],
        displays = displays ?? <InventoryPnPDeviceEntry>[],
        audio = audio ?? <InventoryPnPDeviceEntry>[],
        bluetooth = bluetooth ?? <InventoryPnPDeviceEntry>[],
        printers = printers ?? <InventoryPrinterEntry>[],
        batteries = batteries ?? <InventoryBatteryEntry>[],
        motherboard = motherboard ?? <InventoryMotherboardEntry>[],
        bios = bios ?? <InventoryBiosEntry>[],
        cpu = cpu ?? <InventoryCpuEntry>[],
        memoryModules = memoryModules ?? <InventoryMemoryModuleEntry>[],
        storage = storage ?? <InventoryStorageEntry>[],
        networkAdapters =
            networkAdapters ?? <InventoryNetworkAdapterEntry>[];
  InventoryDomainId domain;
  InventoryStatus status;
  String statusDetail;
  bool truncated;
  int generation;
  int generatedAtUnixMs;
  bool fullResync;
  int cacheTtlMs;
  List<InventoryServiceEntry> services;
  List<InventoryDriverEntry> drivers;
  List<InventorySoftwareEntry> software;
  List<InventoryUsbEntry> usb;
  List<InventoryPciEntry> pci;
  List<InventoryPnPDeviceEntry> displays;
  List<InventoryPnPDeviceEntry> audio;
  List<InventoryPnPDeviceEntry> bluetooth;
  List<InventoryPrinterEntry> printers;
  List<InventoryBatteryEntry> batteries;
  List<InventoryMotherboardEntry> motherboard;
  List<InventoryBiosEntry> bios;
  List<InventoryCpuEntry> cpu;
  List<InventoryMemoryModuleEntry> memoryModules;
  List<InventoryStorageEntry> storage;
  List<InventoryNetworkAdapterEntry> networkAdapters;
}

class GetTimelineSnapshot {
  GetTimelineSnapshot({this.limit = 100, this.channel = 'System'});
  int limit;
  String channel;
}

class TimelineSnapshot {
  TimelineSnapshot({
    List<TimelineEvent>? events,
    this.channel = '',
    this.requestedLimit = 0,
    this.collectedUnixMs = 0,
  }) : events = events ?? <TimelineEvent>[];
  List<TimelineEvent> events;
  String channel;
  int requestedLimit;
  int collectedUnixMs;
}

class StartLiveMonitoring {
  StartLiveMonitoring({this.channel = 'System'});
  String channel;
}

class StopLiveMonitoring {
  StopLiveMonitoring();
}

class HealthStaticInfo {
  HealthStaticInfo({
    this.windowsEdition = '',
    this.windowsVersion = '',
    this.cpuModel = '',
    this.gpuModel = '',
    this.installedRamBytes = 0,
    this.primaryStorageBytes = 0,
    this.activeNetworkAdapter = '',
    this.cpuBaseMhz = 0,
    this.cpuSockets = 0,
    this.cpuCores = 0,
    this.cpuLogicalProcessors = 0,
    this.cpuVirtualizationEnabled = false,
    this.gpuDedicatedBytes = 0,
    this.gpuSharedBytes = 0,
    this.cpuArchitecture = '',
    this.cpuInstructionSet = '',
    this.cpuNumaNodes = 0,
    this.hasCpuSmt = false,
    this.cpuSmtEnabled = false,
    this.hasCpuL1Cache = false,
    this.cpuL1CacheBytes = 0,
    this.hasCpuL2Cache = false,
    this.cpuL2CacheBytes = 0,
    this.hasCpuL3Cache = false,
    this.cpuL3CacheBytes = 0,
    this.cpuVirtualizationVendor = '',
    this.gpuVendor = '',
    this.gpuDriverVersion = '',
    this.gpuDriverDate = '',
    this.hasGpuLuid = false,
    this.gpuLuidHigh = 0,
    this.gpuLuidLow = 0,
    this.gpuDirectxVersion = '',
    this.gpuWddmVersion = '',
    this.hasGpuHardwareScheduling = false,
    this.gpuHardwareScheduling = false,
    this.gpuPcieLinkSpeed = '',
    this.gpuPcieLinkWidth = '',
    this.netManufacturer = '',
    this.netDescription = '',
    this.netMacAddress = '',
    this.netDriverVersion = '',
    this.netDriverDate = '',
    this.netConnectionType = '',
    this.netDuplex = '',
    this.hasNetMtu = false,
    this.netMtu = 0,
    this.hasNetIfIndex = false,
    this.netIfIndex = 0,
    this.hasNetLinkSpeedBps = false,
    this.netLinkSpeedBps = 0,
    this.hasNetDhcp = false,
    this.netDhcpEnabled = false,
    this.netDhcpServer = '',
    this.hasNetLeaseObtained = false,
    this.netLeaseObtainedUnixMs = 0,
    this.hasNetLeaseExpires = false,
    this.netLeaseExpiresUnixMs = 0,
    this.hasMemSlotsUsed = false,
    this.memSlotsUsed = 0,
    this.hasMemModuleCount = false,
    this.memModuleCount = 0,
    this.memDdrGeneration = '',
    this.hasMemSpeedMhz = false,
    this.memSpeedMhz = 0,
    this.memFormFactor = '',
    this.hasMemEcc = false,
    this.memEcc = false,
    this.hasMemChannels = false,
    this.memChannels = 0,
    this.memDimmVendor = '',
    this.memDimmPartNumber = '',
    this.memDimmSerial = '',
    this.diskInterface = '',
    this.diskBus = '',
    this.diskModel = '',
    this.diskSerial = '',
    this.diskFirmware = '',
    this.diskPartitionStyle = '',
    this.hasDiskSectorSize = false,
    this.diskSectorSize = 0,
    this.hasDiskRotationRate = false,
    this.diskRotationRate = 0,
    this.hasDiskTrim = false,
    this.diskTrimSupported = false,
    this.gpuPciLocation = '',
    this.hasGpuResizableBar = false,
    this.gpuResizableBar = false,
  });
  String windowsEdition;
  String windowsVersion;
  String cpuModel;
  String gpuModel;
  int installedRamBytes;
  int primaryStorageBytes;
  String activeNetworkAdapter;
  int cpuBaseMhz;
  int cpuSockets;
  int cpuCores;
  int cpuLogicalProcessors;
  bool cpuVirtualizationEnabled;
  int gpuDedicatedBytes;
  int gpuSharedBytes;
  String cpuArchitecture;
  String cpuInstructionSet;
  int cpuNumaNodes;
  bool hasCpuSmt;
  bool cpuSmtEnabled;
  bool hasCpuL1Cache;
  int cpuL1CacheBytes;
  bool hasCpuL2Cache;
  int cpuL2CacheBytes;
  bool hasCpuL3Cache;
  int cpuL3CacheBytes;
  String cpuVirtualizationVendor;
  String gpuVendor;
  String gpuDriverVersion;
  String gpuDriverDate;
  bool hasGpuLuid;
  int gpuLuidHigh;
  int gpuLuidLow;
  String gpuDirectxVersion;
  String gpuWddmVersion;
  bool hasGpuHardwareScheduling;
  bool gpuHardwareScheduling;
  String gpuPcieLinkSpeed;
  String gpuPcieLinkWidth;
  String gpuPciLocation;
  bool hasGpuResizableBar;
  bool gpuResizableBar;
  String netManufacturer;
  String netDescription;
  String netMacAddress;
  String netDriverVersion;
  String netDriverDate;
  String netConnectionType;
  String netDuplex;
  bool hasNetMtu;
  int netMtu;
  bool hasNetIfIndex;
  int netIfIndex;
  bool hasNetLinkSpeedBps;
  int netLinkSpeedBps;
  bool hasNetDhcp;
  bool netDhcpEnabled;
  String netDhcpServer;
  bool hasNetLeaseObtained;
  int netLeaseObtainedUnixMs;
  bool hasNetLeaseExpires;
  int netLeaseExpiresUnixMs;
  bool hasMemSlotsUsed;
  int memSlotsUsed;
  bool hasMemModuleCount;
  int memModuleCount;
  String memDdrGeneration;
  bool hasMemSpeedMhz;
  int memSpeedMhz;
  String memFormFactor;
  bool hasMemEcc;
  bool memEcc;
  bool hasMemChannels;
  int memChannels;
  String memDimmVendor;
  String memDimmPartNumber;
  String memDimmSerial;
  String diskInterface;
  String diskBus;
  String diskModel;
  String diskSerial;
  String diskFirmware;
  String diskPartitionStyle;
  bool hasDiskSectorSize;
  int diskSectorSize;
  bool hasDiskRotationRate;
  int diskRotationRate;
  bool hasDiskTrim;
  bool diskTrimSupported;
}

class HealthProcessEntry {
  HealthProcessEntry({
    this.pid = 0,
    this.name = '',
    this.hasCpuPercent = false,
    this.cpuPercent = 0.0,
    this.hasMemoryBytes = false,
    this.memoryBytes = 0,
    this.hasGpuPercent = false,
    this.gpuPercent = 0.0,
    this.hasDiskBps = false,
    this.diskBps = 0.0,
    this.hasNetBps = false,
    this.netBps = 0.0,
    this.path = '',
    this.threadCount = 0,
    this.handleCount = 0,
    this.hasCreateTime = false,
    this.createTimeUnixMs = 0,
    this.hasIsCritical = false,
    this.isCritical = false,
    this.hasWorkingSetBytes = false,
    this.workingSetBytes = 0,
    this.hasCommitBytes = false,
    this.commitBytes = 0,
    this.hasPagedPoolBytes = false,
    this.pagedPoolBytes = 0,
    this.hasNonpagedPoolBytes = false,
    this.nonpagedPoolBytes = 0,
    this.hasGpuDedicatedBytes = false,
    this.gpuDedicatedBytes = 0,
    this.hasGpuSharedBytes = false,
    this.gpuSharedBytes = 0,
    this.gpuEngine = '',
    this.hasNetUploadBps = false,
    this.netUploadBps = 0.0,
    this.hasNetDownloadBps = false,
    this.netDownloadBps = 0.0,
    this.hasNetBytesTotal = false,
    this.netBytesTotal = 0,
  });
  int pid;
  String name;
  bool hasCpuPercent;
  double cpuPercent;
  bool hasMemoryBytes;
  int memoryBytes;
  bool hasGpuPercent;
  double gpuPercent;
  bool hasDiskBps;
  double diskBps;
  bool hasNetBps;
  double netBps;
  String path;
  int threadCount;
  int handleCount;
  bool hasCreateTime;
  int createTimeUnixMs;
  bool hasIsCritical;
  bool isCritical;
  bool hasWorkingSetBytes;
  int workingSetBytes;
  bool hasCommitBytes;
  int commitBytes;
  bool hasPagedPoolBytes;
  int pagedPoolBytes;
  bool hasNonpagedPoolBytes;
  int nonpagedPoolBytes;
  bool hasGpuDedicatedBytes;
  int gpuDedicatedBytes;
  bool hasGpuSharedBytes;
  int gpuSharedBytes;
  String gpuEngine;
  bool hasNetUploadBps;
  double netUploadBps;
  bool hasNetDownloadBps;
  double netDownloadBps;
  bool hasNetBytesTotal;
  int netBytesTotal;
}

class HealthProcessInventoryUpdate {
  HealthProcessInventoryUpdate({
    this.seq = 0,
    this.fullResync = false,
    List<HealthProcessEntry>? upserts,
    List<int>? removedPids,
  }) : upserts = upserts ?? <HealthProcessEntry>[],
       removedPids = removedPids ?? <int>[];
  int seq;
  bool fullResync;
  List<HealthProcessEntry> upserts;
  List<int> removedPids;
}

class GetProcessDetails {
  GetProcessDetails({this.pid = 0});
  int pid;
}

class ProcessDetails {
  ProcessDetails({
    this.pid = 0,
    this.name = '',
    this.path = '',
    this.company = '',
    this.commandLine = '',
    this.hasCreateTime = false,
    this.createTimeUnixMs = 0,
    this.threadCount = 0,
    this.handleCount = 0,
    this.hasPath = false,
    this.hasCompany = false,
    this.hasCommandLine = false,
    this.parentPid = 0,
    this.hasParentPid = false,
    this.parentName = '',
    this.hasParentName = false,
    this.user = '',
    this.hasUser = false,
    this.integrityLevel = '',
    this.hasIntegrityLevel = false,
    this.elevated = false,
    this.hasElevated = false,
    this.architecture = '',
    this.hasArchitecture = false,
    this.productName = '',
    this.hasProductName = false,
    this.cpuTimeMs = 0,
    this.hasCpuTime = false,
  });
  int pid;
  String name;
  String path;
  String company;
  String commandLine;
  bool hasCreateTime;
  int createTimeUnixMs;
  int threadCount;
  int handleCount;
  bool hasPath;
  bool hasCompany;
  bool hasCommandLine;
  int parentPid;
  bool hasParentPid;
  String parentName;
  bool hasParentName;
  String user;
  bool hasUser;
  String integrityLevel;
  bool hasIntegrityLevel;
  bool elevated;
  bool hasElevated;
  String architecture;
  bool hasArchitecture;
  String productName;
  bool hasProductName;

  /// User + kernel CPU time since the process started (GetProcessTimes).
  int cpuTimeMs;
  bool hasCpuTime;
}

enum HealthDriveKind {
  unspecified,
  fixed,
  removable,
  remote,
  cdrom,
  ramdisk,
  unknown,
}

HealthDriveKind healthDriveKindFromWire(int v) {
  if (v < 0 || v >= HealthDriveKind.values.length) {
    return HealthDriveKind.unspecified;
  }
  return HealthDriveKind.values[v];
}

class HealthVolume {
  HealthVolume({
    this.id = '',
    this.mountPoint = '',
    this.label = '',
    this.fileSystem = '',
    this.kind = HealthDriveKind.unspecified,
    this.usedBytes = 0,
    this.totalBytes = 0,
    this.hasCapacity = false,
    this.includedInSummary = false,
  });

  String id;
  String mountPoint;
  String label;
  String fileSystem;
  HealthDriveKind kind;
  int usedBytes;
  int totalBytes;
  bool hasCapacity;
  bool includedInSummary;
}

/// Health of one physical disk (issue #12 / #20).
class HealthDiskHealth {
  HealthDiskHealth({
    this.index = 0,
    this.model = '',
    this.bus = '',
    this.hasTempC = false,
    this.tempC = 0.0,
    this.hasFailurePredicted = false,
    this.failurePredicted = false,
    this.hasCriticalWarning = false,
    this.criticalWarning = 0,
    this.hasPercentageUsed = false,
    this.percentageUsed = 0,
    this.hasAvailableSpare = false,
    this.availableSpare = 0,
    this.availableSpareThreshold = 0,
    this.hasPowerOnHours = false,
    this.powerOnHours = 0,
    this.hasUnsafeShutdowns = false,
    this.unsafeShutdowns = 0,
    this.hasMediaErrors = false,
    this.mediaErrors = 0,
    this.hasBytesRead = false,
    this.bytesRead = 0,
    this.hasBytesWritten = false,
    this.bytesWritten = 0,
  });
  int index;
  String model;
  String bus;
  bool hasTempC;
  double tempC;
  bool hasFailurePredicted;
  bool failurePredicted;
  bool hasCriticalWarning;
  int criticalWarning;
  bool hasPercentageUsed;
  int percentageUsed;
  bool hasAvailableSpare;
  int availableSpare;
  int availableSpareThreshold;
  bool hasPowerOnHours;
  int powerOnHours;
  bool hasUnsafeShutdowns;
  int unsafeShutdowns;
  bool hasMediaErrors;
  int mediaErrors;
  bool hasBytesRead;
  int bytesRead;
  bool hasBytesWritten;
  int bytesWritten;
}

/// One hardware GPU adapter (issue #9). Utilization is the busiest engine,
/// each engine summed over its processes, as in Task Manager.
class HealthGpuAdapter {
  HealthGpuAdapter({
    this.luidHigh = 0,
    this.luidLow = 0,
    this.name = '',
    this.vendor = '',
    this.isPrimary = false,
    this.dedicatedTotalBytes = 0,
    this.sharedTotalBytes = 0,
    this.hasPercent = false,
    this.percent = 0.0,
    this.hasDedicatedUsed = false,
    this.dedicatedUsedBytes = 0,
    this.hasSharedUsed = false,
    this.sharedUsedBytes = 0,
  });
  int luidHigh;
  int luidLow;
  String name;
  String vendor;
  /// The adapter the gpu* fields of [HealthSample] describe.
  bool isPrimary;
  int dedicatedTotalBytes;
  int sharedTotalBytes;
  bool hasPercent;
  double percent;
  bool hasDedicatedUsed;
  int dedicatedUsedBytes;
  bool hasSharedUsed;
  int sharedUsedBytes;
}

class HealthPhysicalDisk {
  HealthPhysicalDisk({
    this.id = '',
    this.name = '',
    this.hasReadBps = false,
    this.readBps = 0.0,
    this.hasWriteBps = false,
    this.writeBps = 0.0,
  });

  String id;
  String name;
  bool hasReadBps;
  double readBps;
  bool hasWriteBps;
  double writeBps;
}

class HealthSample {
  HealthSample({
    this.unixMs = 0,
    this.hasCpuPercent = false,
    this.cpuPercent = 0.0,
    this.memoryUsedBytes = 0,
    this.memoryTotalBytes = 0,
    this.hasGpuPercent = false,
    this.gpuPercent = 0.0,
    this.hasNetDownloadBps = false,
    this.netDownloadBps = 0.0,
    this.hasNetUploadBps = false,
    this.netUploadBps = 0.0,
    this.hasDiskReadBps = false,
    this.diskReadBps = 0.0,
    this.hasDiskWriteBps = false,
    this.diskWriteBps = 0.0,
    this.diskUsedBytes = 0,
    this.diskTotalBytes = 0,
    this.uptimeMs = 0,
    this.hasCpuTempC = false,
    this.cpuTempC = 0.0,
    this.hasGpuTempC = false,
    this.gpuTempC = 0.0,
    this.hasSsdTempC = false,
    this.ssdTempC = 0.0,
    this.hasCpuCurrentMhz = false,
    this.cpuCurrentMhz = 0.0,
    this.memoryAvailableBytes = 0,
    this.hasMemoryCommitted = false,
    this.memoryCommittedBytes = 0,
    this.memoryCommitLimitBytes = 0,
    this.hasMemoryCached = false,
    this.memoryCachedBytes = 0,
    this.ipv4 = '',
    this.ipv6 = '',
    this.gateway = '',
    this.dns = '',
    List<HealthProcessEntry>? topCpu,
    List<HealthProcessEntry>? topMemory,
    List<HealthProcessEntry>? topGpu,
    List<HealthProcessEntry>? topDisk,
    List<HealthProcessEntry>? topNetwork,
    List<double>? cpuCorePercent,
    List<HealthVolume>? volumes,
    List<HealthPhysicalDisk>? disks,
    List<HealthDiskHealth>? diskHealth,
    List<HealthGpuAdapter>? gpus,
    this.hasMemoryCompressed = false,
    this.memoryCompressedBytes = 0,
    this.hasMemoryHardwareReserved = false,
    this.memoryHardwareReservedBytes = 0,
    this.hasMemoryPagedPool = false,
    this.memoryPagedPoolBytes = 0,
    this.hasMemoryNonpagedPool = false,
    this.memoryNonpagedPoolBytes = 0,
    this.hasMemoryPageFaultsPerSec = false,
    this.memoryPageFaultsPerSec = 0.0,
    this.hasGpuUtil3d = false,
    this.gpuUtil3d = 0.0,
    this.hasGpuUtilCompute = false,
    this.gpuUtilCompute = 0.0,
    this.hasGpuUtilCopy = false,
    this.gpuUtilCopy = 0.0,
    this.hasGpuUtilVideoDecode = false,
    this.gpuUtilVideoDecode = 0.0,
    this.hasGpuUtilVideoEncode = false,
    this.gpuUtilVideoEncode = 0.0,
    this.hasGpuUtilVideoProcessing = false,
    this.gpuUtilVideoProcessing = 0.0,
    this.hasGpuDedicatedUsed = false,
    this.gpuDedicatedUsedBytes = 0,
    this.hasGpuSharedUsed = false,
    this.gpuSharedUsedBytes = 0,
    this.hasGpuClockMhz = false,
    this.gpuClockMhz = 0.0,
    this.hasGpuMemoryClockMhz = false,
    this.gpuMemoryClockMhz = 0.0,
    this.hasGpuFanRpm = false,
    this.gpuFanRpm = 0.0,
    this.hasGpuPowerPercent = false,
    this.gpuPowerPercent = 0.0,
    this.hasNetPeakDownloadBps = false,
    this.netPeakDownloadBps = 0.0,
    this.hasNetPeakUploadBps = false,
    this.netPeakUploadBps = 0.0,
    this.hasNetAvgDownloadBps = false,
    this.netAvgDownloadBps = 0.0,
    this.hasNetAvgUploadBps = false,
    this.netAvgUploadBps = 0.0,
    this.hasNetUtilizationPercent = false,
    this.netUtilizationPercent = 0.0,
    this.hasNetConnectionMs = false,
    this.netConnectionMs = 0,
    this.hasNetBytesSent = false,
    this.netBytesSent = 0,
    this.hasNetBytesReceived = false,
    this.netBytesReceived = 0,
    this.hasNetPacketsSent = false,
    this.netPacketsSent = 0,
    this.hasNetPacketsReceived = false,
    this.netPacketsReceived = 0,
    this.hasNetErrors = false,
    this.netErrors = 0,
    this.hasNetDrops = false,
    this.netDrops = 0,
    this.netSsid = '',
    this.hasNetSignalPercent = false,
    this.netSignalPercent = 0.0,
    this.netWifiChannel = '',
    this.netWifiFrequency = '',
    this.netWifiSecurity = '',
    this.hasDiskPowerOnHours = false,
    this.diskPowerOnHours = 0,
    this.hasDiskTotalBytesWritten = false,
    this.diskTotalBytesWritten = 0,
    this.hasDiskTotalBytesRead = false,
    this.diskTotalBytesRead = 0,
    this.hasDiskSmartOk = false,
    this.diskSmartOk = false,
  })  : topCpu = topCpu ?? <HealthProcessEntry>[],
        topMemory = topMemory ?? <HealthProcessEntry>[],
        topGpu = topGpu ?? <HealthProcessEntry>[],
        topDisk = topDisk ?? <HealthProcessEntry>[],
        topNetwork = topNetwork ?? <HealthProcessEntry>[],
        cpuCorePercent = cpuCorePercent ?? <double>[],
        volumes = volumes ?? <HealthVolume>[],
        disks = disks ?? <HealthPhysicalDisk>[],
        diskHealth = diskHealth ?? <HealthDiskHealth>[],
        gpus = gpus ?? <HealthGpuAdapter>[];
  int unixMs;
  bool hasCpuPercent;
  double cpuPercent;
  int memoryUsedBytes;
  int memoryTotalBytes;
  bool hasGpuPercent;
  double gpuPercent;
  bool hasNetDownloadBps;
  double netDownloadBps;
  bool hasNetUploadBps;
  double netUploadBps;
  bool hasDiskReadBps;
  double diskReadBps;
  bool hasDiskWriteBps;
  double diskWriteBps;
  int diskUsedBytes;
  int diskTotalBytes;
  int uptimeMs;
  bool hasCpuTempC;
  double cpuTempC;
  bool hasGpuTempC;
  double gpuTempC;
  bool hasSsdTempC;
  double ssdTempC;
  bool hasCpuCurrentMhz;
  double cpuCurrentMhz;
  int memoryAvailableBytes;
  bool hasMemoryCommitted;
  int memoryCommittedBytes;
  int memoryCommitLimitBytes;
  bool hasMemoryCached;
  int memoryCachedBytes;
  String ipv4;
  String ipv6;
  String gateway;
  String dns;
  List<HealthProcessEntry> topCpu;
  List<HealthProcessEntry> topMemory;
  List<HealthProcessEntry> topGpu;
  List<HealthProcessEntry> topDisk;
  List<HealthProcessEntry> topNetwork;
  List<double> cpuCorePercent;
  List<HealthVolume> volumes;
  List<HealthPhysicalDisk> disks;
  bool hasMemoryCompressed;
  int memoryCompressedBytes;
  bool hasMemoryHardwareReserved;
  int memoryHardwareReservedBytes;
  bool hasMemoryPagedPool;
  int memoryPagedPoolBytes;
  bool hasMemoryNonpagedPool;
  int memoryNonpagedPoolBytes;
  bool hasMemoryPageFaultsPerSec;
  double memoryPageFaultsPerSec;
  bool hasGpuUtil3d;
  double gpuUtil3d;
  bool hasGpuUtilCompute;
  double gpuUtilCompute;
  bool hasGpuUtilCopy;
  double gpuUtilCopy;
  bool hasGpuUtilVideoDecode;
  double gpuUtilVideoDecode;
  bool hasGpuUtilVideoEncode;
  double gpuUtilVideoEncode;
  bool hasGpuUtilVideoProcessing;
  double gpuUtilVideoProcessing;
  bool hasGpuDedicatedUsed;
  int gpuDedicatedUsedBytes;
  bool hasGpuSharedUsed;
  int gpuSharedUsedBytes;
  bool hasGpuClockMhz;
  double gpuClockMhz;
  bool hasGpuMemoryClockMhz;
  double gpuMemoryClockMhz;
  bool hasGpuFanRpm;
  double gpuFanRpm;
  bool hasGpuPowerPercent;
  double gpuPowerPercent;
  bool hasNetPeakDownloadBps;
  double netPeakDownloadBps;
  bool hasNetPeakUploadBps;
  double netPeakUploadBps;
  bool hasNetAvgDownloadBps;
  double netAvgDownloadBps;
  bool hasNetAvgUploadBps;
  double netAvgUploadBps;
  bool hasNetUtilizationPercent;
  double netUtilizationPercent;
  bool hasNetConnectionMs;
  int netConnectionMs;
  bool hasNetBytesSent;
  int netBytesSent;
  bool hasNetBytesReceived;
  int netBytesReceived;
  bool hasNetPacketsSent;
  int netPacketsSent;
  bool hasNetPacketsReceived;
  int netPacketsReceived;
  bool hasNetErrors;
  int netErrors;
  bool hasNetDrops;
  int netDrops;
  String netSsid;
  bool hasNetSignalPercent;
  double netSignalPercent;
  String netWifiChannel;
  String netWifiFrequency;
  String netWifiSecurity;
  bool hasDiskPowerOnHours;
  int diskPowerOnHours;
  bool hasDiskTotalBytesWritten;
  int diskTotalBytesWritten;
  bool hasDiskTotalBytesRead;
  int diskTotalBytesRead;
  bool hasDiskSmartOk;
  bool diskSmartOk;
  /// Every physical disk (issue #12 / #20).
  List<HealthDiskHealth> diskHealth;
  /// Every hardware GPU (issue #9); empty from services before 1.5.
  List<HealthGpuAdapter> gpus;
}

class GetHealthSnapshot {
  GetHealthSnapshot();
}

class HealthSnapshot {
  HealthSnapshot({HealthStaticInfo? info, HealthSample? sample})
      : info = info ?? HealthStaticInfo(),
        sample = sample ?? HealthSample();
  HealthStaticInfo info;
  HealthSample sample;
}

class HealthUpdate {
  HealthUpdate({HealthSample? sample, this.processInventory})
    : sample = sample ?? HealthSample();
  HealthSample sample;
  HealthProcessInventoryUpdate? processInventory;
}

class StartHealthMonitoring {
  StartHealthMonitoring();
}

class StopHealthMonitoring {
  StopHealthMonitoring();
}

class GetDiagnosticsSnapshot {
  GetDiagnosticsSnapshot();
}

/// Pipeline stage health: 0 = healthy, 1 = warning, 2 = error.
class DiagnosticsSnapshot {
  DiagnosticsSnapshot({
    this.serviceVersion = '',
    this.protocolVersion = 0,
    this.serviceStartUnixMs = 0,
    this.serviceUptimeMs = 0,
    this.runMode = '',
    this.ipcListening = false,
    this.liveSubscribed = false,
    this.liveChannel = '',
    this.liveEventsPushed = 0,
    this.liveEventsDropped = 0,
    this.liveSubscriberReconnects = 0,
    this.lastLiveEventUnixMs = 0,
    this.lastLiveEventTitle = '',
    this.liveQueueDepth = 0,
    this.liveQueueCapacity = 0,
    this.ipcMessagesReceived = 0,
    this.ipcMessagesSent = 0,
    this.ipcErrors = 0,
    this.connectedClients = 0,
    this.servicePid = 0,
    this.hasCpuPercent = false,
    this.cpuPercent = 0.0,
    this.workingSetBytes = 0,
    this.threadCount = 0,
    this.handleCount = 0,
    this.stageEventLog = 0,
    this.stageCollector = 0,
    this.stageIntelligence = 0,
    this.stageIpc = 0,
    this.stageDetail = '',
    this.windowsEdition = '',
    this.windowsVersion = '',
    this.executablePath = '',
    this.buildVersion = '',
    this.gitCommit = '',
    this.binarySha256 = '',
    this.installPath = '',
    this.hasPathsMatch = false,
    this.pathsMatch = false,
    this.scmState = '',
    this.scmStartupType = '',
    this.ipcBytesReceived = 0,
    this.ipcBytesSent = 0,
    this.hasIpcMessagesPerSec = false,
    this.ipcMessagesPerSec = 0.0,
    this.hasIpcBytesPerSec = false,
    this.ipcBytesPerSec = 0.0,
    this.healthMonitoringActive = false,
    this.healthSampleRateHz = 0.0,
    this.networkEtwRunning = false,
    this.networkEtwLastError = '',
    this.stageEventLogDetail = '',
    this.stageCollectorDetail = '',
    this.stageIntelligenceDetail = '',
    this.stageIpcDetail = '',
  });
  String serviceVersion;
  int protocolVersion;
  int serviceStartUnixMs;
  int serviceUptimeMs;
  String runMode;
  bool ipcListening;

  bool liveSubscribed;
  String liveChannel;
  int liveEventsPushed;
  int liveEventsDropped;
  int liveSubscriberReconnects;
  int lastLiveEventUnixMs;
  String lastLiveEventTitle;
  int liveQueueDepth;
  int liveQueueCapacity;

  int ipcMessagesReceived;
  int ipcMessagesSent;
  int ipcErrors;
  int connectedClients;

  int servicePid;
  bool hasCpuPercent;
  double cpuPercent;
  int workingSetBytes;
  int threadCount;
  int handleCount;

  int stageEventLog;
  int stageCollector;
  int stageIntelligence;
  int stageIpc;
  String stageDetail;

  String windowsEdition;
  String windowsVersion;

  String executablePath;
  String buildVersion;
  String gitCommit;
  String binarySha256;
  String installPath;
  bool hasPathsMatch;
  bool pathsMatch;
  String scmState;
  String scmStartupType;

  int ipcBytesReceived;
  int ipcBytesSent;
  bool hasIpcMessagesPerSec;
  double ipcMessagesPerSec;
  bool hasIpcBytesPerSec;
  double ipcBytesPerSec;

  bool healthMonitoringActive;
  double healthSampleRateHz;
  bool networkEtwRunning;
  String networkEtwLastError;

  String stageEventLogDetail;
  String stageCollectorDetail;
  String stageIntelligenceDetail;
  String stageIpcDetail;
}

class InjectDiagnosticsTestEvent {
  InjectDiagnosticsTestEvent();
}

// --- Crash history (doc 43) ---

/// Wire order matches `CrashKind` in pulse.proto.
enum CrashKind {
  unspecified,
  appCrash,
  appHang,
  blueScreen,
  unexpectedRestart,
  gpuReset,
  serviceCrash,
  hardwareError,
}

/// Wire order matches `FaultingModuleOrigin` in pulse.proto.
enum FaultingModuleOrigin { unknown, app, windows, driver, other }

/// One event of a [CrashGroup]; load it with [GetTimelineEventDetail].
class CrashOccurrence {
  CrashOccurrence({
    this.timestampUnixMs = 0,
    this.channel = '',
    this.recordId = 0,
    this.version = '',
  });
  int timestampUnixMs;
  String channel;
  int recordId;
  String version;
}

class CrashVersion {
  CrashVersion({this.version = '', this.count = 0, this.lastUnixMs = 0});
  String version;
  int count;
  int lastUnixMs;
}

/// Crashes with the same cause, explained from the newest event.
class CrashGroup {
  CrashGroup({
    this.kind = CrashKind.unspecified,
    this.key = '',
    this.subject = '',
    this.moduleName = '',
    this.modulePath = '',
    this.moduleCompany = '',
    this.moduleOrigin = FaultingModuleOrigin.unknown,
    this.code = 0,
    this.hasCode = false,
    this.title = '',
    this.summary = '',
    this.recommendation = '',
    this.count = 0,
    this.firstUnixMs = 0,
    this.lastUnixMs = 0,
    List<int>? occurrenceUnixMs,
    List<CrashVersion>? versions,
    List<CrashOccurrence>? recent,
  })  : occurrenceUnixMs = occurrenceUnixMs ?? <int>[],
        versions = versions ?? <CrashVersion>[],
        recent = recent ?? <CrashOccurrence>[];
  CrashKind kind;
  String key;
  String subject;
  String moduleName;
  String modulePath;
  String moduleCompany;
  FaultingModuleOrigin moduleOrigin;
  int code;
  bool hasCode;
  String title;
  String summary;
  String recommendation;
  int count;
  int firstUnixMs;
  int lastUnixMs;
  /// Newest first; capped by the service.
  List<int> occurrenceUnixMs;
  /// Most crashes first.
  List<CrashVersion> versions;
  /// Newest first; capped by the service.
  List<CrashOccurrence> recent;
}

class GetCrashHistory {
  GetCrashHistory({this.days = 0});
  int days;
}

class CrashHistory {
  CrashHistory({
    this.days = 0,
    this.collectedUnixMs = 0,
    List<CrashGroup>? groups,
    this.scannedEvents = 0,
    this.truncated = false,
    List<String>? unreadableChannels,
  })  : groups = groups ?? <CrashGroup>[],
        unreadableChannels = unreadableChannels ?? <String>[];
  int days;
  int collectedUnixMs;
  /// Ordered by their newest event.
  List<CrashGroup> groups;
  int scannedEvents;
  /// The service hit its read cap; older events were not read.
  bool truncated;
  List<String> unreadableChannels;
}

// --- Event Log channels (ADR-016) ---

/// Wire order matches `EventLogChannelType` in pulse.proto.
enum EventLogChannelType { unknown, admin, operational, analytic, debug }

/// Whether PulseService can read the channel.
/// Wire order matches `EventLogChannelAccess` in pulse.proto.
enum EventLogChannelAccess { unknown, readable, denied, notFound, error }

class EventLogChannelInfo {
  EventLogChannelInfo({
    this.path = '',
    this.type = EventLogChannelType.unknown,
    this.enabled = false,
    this.access = EventLogChannelAccess.unknown,
    this.recordCount = 0,
    this.hasRecordCount = false,
    this.builtIn = false,
    this.tracked = false,
    this.detail = '',
  });
  String path;
  EventLogChannelType type;
  bool enabled;
  EventLogChannelAccess access;
  int recordCount;
  bool hasRecordCount;
  /// Always read by Pulse; cannot be unchecked.
  bool builtIn;
  /// Chosen by the user.
  bool tracked;
  /// Win32 error text when [access] is not readable.
  String detail;
}

class ListEventLogChannels {
  ListEventLogChannels();
}

class EventLogChannelList {
  EventLogChannelList({
    List<EventLogChannelInfo>? channels,
    this.collectedUnixMs = 0,
    this.maxTracked = 0,
    this.skippedChannels = 0,
  }) : channels = channels ?? <EventLogChannelInfo>[];
  /// Sorted by path, case-insensitive.
  List<EventLogChannelInfo> channels;
  int collectedUnixMs;
  int maxTracked;
  /// Analytic / Debug channels the service left out.
  int skippedChannels;
}

/// The full tracked list; replaces the previous one.
class SetTrackedChannels {
  SetTrackedChannels({List<String>? channels})
      : channels = channels ?? <String>[];
  List<String> channels;
}

/// Wire order matches `TrackedChannelStatus` in pulse.proto.
enum TrackedChannelStatus {
  unspecified,
  tracked,
  disabled,
  accessDenied,
  notFound,
  unsupportedType,
  overLimit,
  builtIn,
  failed,
}

class TrackedChannelResult {
  TrackedChannelResult({
    this.path = '',
    this.status = TrackedChannelStatus.unspecified,
    this.detail = '',
  });
  String path;
  TrackedChannelStatus status;
  String detail;
}

class TrackedChannels {
  TrackedChannels({
    List<TrackedChannelResult>? results,
    this.maxTracked = 0,
    List<String>? tracked,
  })  : results = results ?? <TrackedChannelResult>[],
        tracked = tracked ?? <String>[];
  /// One per requested channel, in request order.
  List<TrackedChannelResult> results;
  int maxTracked;
  /// The list the service saved.
  List<String> tracked;
}

class Envelope {
  Envelope({this.requestId = 0, this.body});
  int requestId;
  Object? body;
}

void _writeVarint(int value, BytesBuilder out) {
  // Protobuf varints are unsigned. Dart `int` is signed, so uint64 values with
  // the high bit set appear negative and must be encoded via toUnsigned(64).
  var v = value.toUnsigned(64);
  while (v >= 0x80) {
    out.addByte((v & 0x7f) | 0x80);
    v >>= 7;
  }
  out.addByte(v & 0x7f);
}

void _writeTag(int field, int wire, BytesBuilder out) {
  _writeVarint((field << 3) | wire, out);
}

void _writeString(int field, String s, BytesBuilder out) {
  final bytes = utf8.encode(s);
  _writeTag(field, 2, out);
  _writeVarint(bytes.length, out);
  out.add(bytes);
}

void _writeU64(int field, int v, BytesBuilder out) {
  _writeTag(field, 0, out);
  _writeVarint(v, out);
}

void _writeBool(int field, bool v, BytesBuilder out) {
  _writeU64(field, v ? 1 : 0, out);
}

void _writeDouble(int field, double v, BytesBuilder out) {
  _writeTag(field, 1, out);
  final bd = ByteData(8);
  bd.setFloat64(0, v, Endian.little);
  out.add(bd.buffer.asUint8List());
}

Uint8List _encodeClientHello(ClientHello m) {
  final out = BytesBuilder();
  _writeU64(1, m.protocolVersion, out);
  _writeString(2, m.clientName, out);
  _writeString(3, m.clientVersion, out);
  return out.toBytes();
}

Uint8List _encodeServerHello(ServerHello m) {
  final out = BytesBuilder();
  _writeU64(1, m.protocolVersion, out);
  _writeString(2, m.serviceVersion, out);
  return out.toBytes();
}

Uint8List _encodePing(Ping m) {
  final out = BytesBuilder();
  _writeU64(1, m.nonce, out);
  _writeU64(2, m.unixMs, out);
  return out.toBytes();
}

Uint8List _encodePong(Pong m) {
  final out = BytesBuilder();
  _writeU64(1, m.nonce, out);
  _writeU64(2, m.unixMs, out);
  _writeString(3, m.serviceVersion, out);
  return out.toBytes();
}

Uint8List _encodeHeartbeat(Heartbeat m) {
  final out = BytesBuilder();
  _writeU64(1, m.unixMs, out);
  return out.toBytes();
}

Uint8List _encodeError(ErrorResponse m) {
  final out = BytesBuilder();
  _writeU64(1, m.code, out);
  _writeString(2, m.message, out);
  _writeString(3, m.technicalDetail, out);
  _writeString(4, m.component, out);
  return out.toBytes();
}

Uint8List _encodeTimelineEvent(TimelineEvent m) {
  final out = BytesBuilder();
  _writeString(1, m.eventId, out);
  _writeU64(2, m.timestampUnixMs, out);
  _writeString(3, m.timestampIso, out);
  _writeU64(4, m.severity, out);
  _writeString(5, m.channel, out);
  _writeString(6, m.providerName, out);
  _writeU64(7, m.winEventId, out);
  _writeU64(8, m.recordId, out);
  _writeString(9, m.computerName, out);
  _writeString(10, m.summary, out);
  _writeString(11, m.technicalSummary, out);
  _writeString(12, m.message, out);
  _writeString(13, m.title, out);
  _writeString(14, m.recommendation, out);
  _writeU64(15, m.actionRequired ? 1 : 0, out);
  _writeU64(16, m.importance, out);
  _writeString(17, m.category, out);
  _writeU64(18, m.task, out);
  _writeBool(19, m.hasTask, out);
  _writeU64(20, m.opcode, out);
  _writeBool(21, m.hasOpcode, out);
  _writeU64(22, m.keywords, out);
  _writeBool(23, m.hasKeywords, out);
  _writeU64(24, m.processId, out);
  _writeBool(25, m.hasProcessId, out);
  _writeString(26, m.processName, out);
  _writeU64(27, m.threadId, out);
  _writeBool(28, m.hasThreadId, out);
  _writeString(29, m.userSid, out);
  _writeString(30, m.activityId, out);
  _writeString(31, m.relatedActivityId, out);
  _writeString(32, m.levelName, out);
  _writeString(33, m.rawXml, out);
  return out.toBytes();
}

Uint8List _encodeGetTimelineEventDetail(GetTimelineEventDetail m) {
  final out = BytesBuilder();
  _writeString(1, m.channel, out);
  _writeU64(2, m.recordId, out);
  return out.toBytes();
}

Uint8List _encodeTimelineEventDetail(TimelineEventDetail m) {
  final out = BytesBuilder();
  _writeBool(1, m.found, out);
  _writeBytesField(2, _encodeTimelineEvent(m.event), out);
  return out.toBytes();
}

Uint8List _encodeInventoryServiceEntry(InventoryServiceEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.displayName, out);
  _writeString(3, m.state, out);
  _writeString(4, m.startType, out);
  _writeString(5, m.account, out);
  _writeString(6, m.binaryPath, out);
  _writeString(7, m.description, out);
  return out.toBytes();
}

Uint8List _encodeInventoryDriverEntry(InventoryDriverEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.displayName, out);
  _writeString(3, m.state, out);
  _writeString(4, m.startType, out);
  _writeString(5, m.binaryPath, out);
  _writeString(6, m.description, out);
  _writeString(7, m.driverType, out);
  return out.toBytes();
}

Uint8List _encodeInventorySoftwareEntry(InventorySoftwareEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.displayName, out);
  _writeString(3, m.version, out);
  _writeString(4, m.publisher, out);
  _writeString(5, m.installDate, out);
  _writeString(6, m.installLocation, out);
  _writeU64(7, m.estimatedSizeBytes, out);
  _writeBool(8, m.hasEstimatedSize, out);
  _writeBool(9, m.systemComponent, out);
  _writeString(10, m.architecture, out);
  return out.toBytes();
}

Uint8List _encodeInventoryUsbEntry(InventoryUsbEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.description, out);
  _writeString(3, m.hardwareId, out);
  _writeString(4, m.manufacturer, out);
  _writeString(5, m.service, out);
  _writeString(6, m.className, out);
  _writeString(7, m.classGuid, out);
  _writeU64(8, m.problemCode, out);
  _writeBool(9, m.hasProblemCode, out);
  return out.toBytes();
}

Uint8List _encodeInventoryPciEntry(InventoryPciEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.description, out);
  _writeString(3, m.hardwareId, out);
  _writeString(4, m.manufacturer, out);
  _writeString(5, m.service, out);
  _writeString(6, m.className, out);
  _writeString(7, m.classGuid, out);
  _writeString(8, m.locationInfo, out);
  _writeU64(9, m.problemCode, out);
  _writeBool(10, m.hasProblemCode, out);
  return out.toBytes();
}

Uint8List _encodeInventoryPnPDeviceEntry(InventoryPnPDeviceEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.description, out);
  _writeString(3, m.hardwareId, out);
  _writeString(4, m.manufacturer, out);
  _writeString(5, m.service, out);
  _writeString(6, m.className, out);
  _writeString(7, m.classGuid, out);
  _writeString(8, m.locationInfo, out);
  _writeU64(9, m.problemCode, out);
  _writeBool(10, m.hasProblemCode, out);
  _writeString(11, m.adapterName, out);
  _writeBool(12, m.descriptionFromEnumDisplay, out);
  return out.toBytes();
}

Uint8List _encodeInventoryPrinterEntry(InventoryPrinterEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.portName, out);
  _writeString(3, m.driverName, out);
  _writeString(4, m.location, out);
  _writeString(5, m.comment, out);
  _writeBool(6, m.isShared, out);
  _writeBool(7, m.isDefault, out);
  _writeBool(8, m.isNetwork, out);
  _writeU64(9, m.attributes, out);
  _writeBool(10, m.hasAttributes, out);
  return out.toBytes();
}

Uint8List _encodeInventoryBatteryEntry(InventoryBatteryEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.description, out);
  _writeString(3, m.manufacturer, out);
  _writeString(4, m.chemistry, out);
  _writeU64(5, m.designCapacityMwh, out);
  _writeBool(6, m.hasDesignCapacity, out);
  _writeU64(7, m.fullChargedCapacityMwh, out);
  _writeBool(8, m.hasFullChargedCapacity, out);
  _writeU64(9, m.cycleCount, out);
  _writeBool(10, m.hasCycleCount, out);
  _writeU64(11, m.capacityPercent, out);
  _writeBool(12, m.hasCapacityPercent, out);
  _writeString(13, m.powerState, out);
  _writeBool(14, m.fromSystemPowerFallback, out);
  return out.toBytes();
}

Uint8List _encodeInventoryMotherboardEntry(InventoryMotherboardEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.manufacturer, out);
  _writeString(3, m.product, out);
  _writeString(4, m.version, out);
  _writeString(5, m.serialNumber, out);
  _writeString(6, m.assetTag, out);
  _writeString(7, m.locationInChassis, out);
  _writeString(8, m.boardType, out);
  return out.toBytes();
}

Uint8List _encodeInventoryBiosEntry(InventoryBiosEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.vendor, out);
  _writeString(3, m.version, out);
  _writeString(4, m.releaseDate, out);
  _writeU64(5, m.majorRelease, out);
  _writeBool(6, m.hasMajorRelease, out);
  _writeU64(7, m.minorRelease, out);
  _writeBool(8, m.hasMinorRelease, out);
  _writeU64(9, m.romSizeBytes, out);
  _writeBool(10, m.hasRomSizeBytes, out);
  _writeBool(11, m.uefiCapable, out);
  _writeBool(12, m.hasUefiCapable, out);
  return out.toBytes();
}

Uint8List _encodeInventoryCpuEntry(InventoryCpuEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.name, out);
  _writeString(3, m.manufacturer, out);
  _writeString(4, m.architecture, out);
  _writeU64(5, m.sockets, out);
  _writeBool(6, m.hasSockets, out);
  _writeU64(7, m.physicalCores, out);
  _writeBool(8, m.hasPhysicalCores, out);
  _writeU64(9, m.logicalProcessors, out);
  _writeBool(10, m.hasLogicalProcessors, out);
  _writeU64(11, m.baseClockMhz, out);
  _writeBool(12, m.hasBaseClockMhz, out);
  _writeU64(13, m.numaNodes, out);
  _writeBool(14, m.hasNumaNodes, out);
  _writeU64(15, m.l1CacheBytes, out);
  _writeBool(16, m.hasL1CacheBytes, out);
  _writeU64(17, m.l2CacheBytes, out);
  _writeBool(18, m.hasL2CacheBytes, out);
  _writeU64(19, m.l3CacheBytes, out);
  _writeBool(20, m.hasL3CacheBytes, out);
  _writeString(21, m.instructionSet, out);
  _writeBool(22, m.smtEnabled, out);
  _writeBool(23, m.hasSmtEnabled, out);
  _writeString(24, m.virtualizationVendor, out);
  return out.toBytes();
}

Uint8List _encodeInventoryMemoryModuleEntry(InventoryMemoryModuleEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.bankLocator, out);
  _writeString(3, m.manufacturer, out);
  _writeString(4, m.partNumber, out);
  _writeString(5, m.serialNumber, out);
  _writeU64(6, m.sizeBytes, out);
  _writeBool(7, m.hasSizeBytes, out);
  _writeU64(8, m.speedMts, out);
  _writeBool(9, m.hasSpeedMts, out);
  _writeU64(10, m.configuredSpeedMts, out);
  _writeBool(11, m.hasConfiguredSpeedMts, out);
  _writeString(12, m.formFactor, out);
  _writeString(13, m.memoryType, out);
  _writeBool(14, m.isEcc, out);
  _writeBool(15, m.hasIsEcc, out);
  _writeU64(16, m.totalWidthBits, out);
  _writeBool(17, m.hasTotalWidthBits, out);
  _writeU64(18, m.dataWidthBits, out);
  _writeBool(19, m.hasDataWidthBits, out);
  _writeU64(20, m.configuredVoltageMv, out);
  _writeBool(21, m.hasConfiguredVoltageMv, out);
  _writeBool(22, m.populated, out);
  return out.toBytes();
}

Uint8List _encodeInventoryStorageEntry(InventoryStorageEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.devicePath, out);
  _writeU64(3, m.physicalDriveNumber, out);
  _writeBool(4, m.hasPhysicalDriveNumber, out);
  _writeString(5, m.model, out);
  _writeString(6, m.vendor, out);
  _writeString(7, m.serialNumber, out);
  _writeString(8, m.firmwareRevision, out);
  _writeString(9, m.busType, out);
  _writeString(10, m.mediaType, out);
  _writeU64(11, m.sizeBytes, out);
  _writeBool(12, m.hasSizeBytes, out);
  _writeU64(13, m.sectorSizeBytes, out);
  _writeBool(14, m.hasSectorSizeBytes, out);
  _writeString(15, m.partitionStyle, out);
  _writeBool(16, m.isRemovable, out);
  _writeBool(17, m.hasIsRemovable, out);
  _writeBool(18, m.trimSupported, out);
  _writeBool(19, m.hasTrimSupported, out);
  _writeString(20, m.manufacturer, out);
  _writeString(21, m.description, out);
  return out.toBytes();
}

Uint8List _encodeInventoryNetworkAdapterEntry(InventoryNetworkAdapterEntry m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.description, out);
  _writeString(3, m.friendlyName, out);
  _writeString(4, m.macAddress, out);
  _writeString(5, m.connectionType, out);
  _writeU64(6, m.ifIndex, out);
  _writeBool(7, m.hasIfIndex, out);
  _writeU64(8, m.mtu, out);
  _writeBool(9, m.hasMtu, out);
  _writeString(10, m.operationalStatus, out);
  _writeBool(11, m.dhcpEnabled, out);
  _writeBool(12, m.hasDhcpEnabled, out);
  _writeU64(13, m.linkSpeedBps, out);
  _writeBool(14, m.hasLinkSpeedBps, out);
  _writeBool(15, m.isLoopback, out);
  for (final addr in m.ipv4Addresses) {
    _writeString(16, addr, out);
  }
  for (final addr in m.ipv6Addresses) {
    _writeString(17, addr, out);
  }
  for (final addr in m.gatewayAddresses) {
    _writeString(18, addr, out);
  }
  for (final addr in m.dnsAddresses) {
    _writeString(19, addr, out);
  }
  _writeString(20, m.driverProvider, out);
  _writeString(21, m.driverVersion, out);
  _writeString(22, m.driverDate, out);
  return out.toBytes();
}

Uint8List _encodeGetInventoryDomain(GetInventoryDomain m) {
  final out = BytesBuilder();
  _writeU64(1, m.domain.index, out);
  _writeBool(2, m.forceRefresh, out);
  _writeU64(3, m.sinceGeneration, out);
  _writeU64(4, m.limit, out);
  return out.toBytes();
}

Uint8List _encodeInventoryDomainSnapshot(InventoryDomainSnapshot m) {
  final out = BytesBuilder();
  _writeU64(1, m.domain.index, out);
  _writeU64(2, m.status.index, out);
  _writeString(3, m.statusDetail, out);
  _writeBool(4, m.truncated, out);
  _writeU64(5, m.generation, out);
  _writeU64(6, m.generatedAtUnixMs, out);
  _writeBool(7, m.fullResync, out);
  _writeU64(8, m.cacheTtlMs, out);
  for (final e in m.services) {
    _writeBytesField(10, _encodeInventoryServiceEntry(e), out);
  }
  for (final e in m.drivers) {
    _writeBytesField(11, _encodeInventoryDriverEntry(e), out);
  }
  for (final e in m.software) {
    _writeBytesField(12, _encodeInventorySoftwareEntry(e), out);
  }
  for (final e in m.usb) {
    _writeBytesField(13, _encodeInventoryUsbEntry(e), out);
  }
  for (final e in m.pci) {
    _writeBytesField(14, _encodeInventoryPciEntry(e), out);
  }
  for (final e in m.displays) {
    _writeBytesField(15, _encodeInventoryPnPDeviceEntry(e), out);
  }
  for (final e in m.audio) {
    _writeBytesField(16, _encodeInventoryPnPDeviceEntry(e), out);
  }
  for (final e in m.bluetooth) {
    _writeBytesField(17, _encodeInventoryPnPDeviceEntry(e), out);
  }
  for (final e in m.printers) {
    _writeBytesField(18, _encodeInventoryPrinterEntry(e), out);
  }
  for (final e in m.batteries) {
    _writeBytesField(19, _encodeInventoryBatteryEntry(e), out);
  }
  for (final e in m.motherboard) {
    _writeBytesField(20, _encodeInventoryMotherboardEntry(e), out);
  }
  for (final e in m.bios) {
    _writeBytesField(21, _encodeInventoryBiosEntry(e), out);
  }
  for (final e in m.cpu) {
    _writeBytesField(22, _encodeInventoryCpuEntry(e), out);
  }
  for (final e in m.memoryModules) {
    _writeBytesField(23, _encodeInventoryMemoryModuleEntry(e), out);
  }
  for (final e in m.storage) {
    _writeBytesField(24, _encodeInventoryStorageEntry(e), out);
  }
  for (final e in m.networkAdapters) {
    _writeBytesField(25, _encodeInventoryNetworkAdapterEntry(e), out);
  }
  return out.toBytes();
}

Uint8List _encodeGetTimelineSnapshot(GetTimelineSnapshot m) {
  final out = BytesBuilder();
  _writeU64(1, m.limit, out);
  _writeString(2, m.channel, out);
  return out.toBytes();
}

Uint8List _encodeTimelineSnapshot(TimelineSnapshot m) {
  final out = BytesBuilder();
  for (final event in m.events) {
    _writeBytesField(1, _encodeTimelineEvent(event), out);
  }
  _writeString(2, m.channel, out);
  _writeU64(3, m.requestedLimit, out);
  _writeU64(4, m.collectedUnixMs, out);
  return out.toBytes();
}

Uint8List _encodeStartLiveMonitoring(StartLiveMonitoring m) {
  final out = BytesBuilder();
  _writeString(1, m.channel, out);
  return out.toBytes();
}

Uint8List _encodeStopLiveMonitoring(StopLiveMonitoring _) {
  return Uint8List(0);
}

Uint8List _encodeHealthProcessEntry(HealthProcessEntry m) {
  final out = BytesBuilder();
  _writeU64(1, m.pid, out);
  _writeString(2, m.name, out);
  _writeBool(3, m.hasCpuPercent, out);
  _writeDouble(4, m.cpuPercent, out);
  _writeBool(5, m.hasMemoryBytes, out);
  _writeU64(6, m.memoryBytes, out);
  _writeBool(7, m.hasGpuPercent, out);
  _writeDouble(8, m.gpuPercent, out);
  _writeBool(9, m.hasDiskBps, out);
  _writeDouble(10, m.diskBps, out);
  _writeBool(11, m.hasNetBps, out);
  _writeDouble(12, m.netBps, out);
  _writeString(13, m.path, out);
  _writeU64(14, m.threadCount, out);
  _writeU64(15, m.handleCount, out);
  _writeBool(16, m.hasCreateTime, out);
  _writeU64(17, m.createTimeUnixMs, out);
  _writeBool(18, m.hasIsCritical, out);
  _writeBool(19, m.isCritical, out);
  _writeBool(20, m.hasWorkingSetBytes, out);
  _writeU64(21, m.workingSetBytes, out);
  _writeBool(22, m.hasCommitBytes, out);
  _writeU64(23, m.commitBytes, out);
  _writeBool(24, m.hasPagedPoolBytes, out);
  _writeU64(25, m.pagedPoolBytes, out);
  _writeBool(26, m.hasNonpagedPoolBytes, out);
  _writeU64(27, m.nonpagedPoolBytes, out);
  _writeBool(28, m.hasGpuDedicatedBytes, out);
  _writeU64(29, m.gpuDedicatedBytes, out);
  _writeBool(30, m.hasGpuSharedBytes, out);
  _writeU64(31, m.gpuSharedBytes, out);
  _writeString(32, m.gpuEngine, out);
  _writeBool(33, m.hasNetUploadBps, out);
  _writeDouble(34, m.netUploadBps, out);
  _writeBool(35, m.hasNetDownloadBps, out);
  _writeDouble(36, m.netDownloadBps, out);
  _writeBool(37, m.hasNetBytesTotal, out);
  _writeU64(38, m.netBytesTotal, out);
  return out.toBytes();
}

Uint8List _encodeHealthProcessInventoryUpdate(HealthProcessInventoryUpdate m) {
  final out = BytesBuilder();
  _writeU64(1, m.seq, out);
  _writeBool(2, m.fullResync, out);
  for (final e in m.upserts) {
    _writeBytesField(3, _encodeHealthProcessEntry(e), out);
  }
  for (final pid in m.removedPids) {
    _writeU64(4, pid, out);
  }
  return out.toBytes();
}

Uint8List _encodeGetProcessDetails(GetProcessDetails m) {
  final out = BytesBuilder();
  _writeU64(1, m.pid, out);
  return out.toBytes();
}

Uint8List _encodeProcessDetails(ProcessDetails m) {
  final out = BytesBuilder();
  _writeU64(1, m.pid, out);
  _writeString(2, m.name, out);
  _writeString(3, m.path, out);
  _writeString(4, m.company, out);
  _writeString(5, m.commandLine, out);
  _writeBool(6, m.hasCreateTime, out);
  _writeU64(7, m.createTimeUnixMs, out);
  _writeU64(8, m.threadCount, out);
  _writeU64(9, m.handleCount, out);
  _writeBool(10, m.hasPath, out);
  _writeBool(11, m.hasCompany, out);
  _writeBool(12, m.hasCommandLine, out);
  _writeU64(13, m.parentPid, out);
  _writeBool(14, m.hasParentPid, out);
  _writeString(15, m.parentName, out);
  _writeBool(16, m.hasParentName, out);
  _writeString(17, m.user, out);
  _writeBool(18, m.hasUser, out);
  _writeString(19, m.integrityLevel, out);
  _writeBool(20, m.hasIntegrityLevel, out);
  _writeBool(21, m.elevated, out);
  _writeBool(22, m.hasElevated, out);
  _writeString(23, m.architecture, out);
  _writeBool(24, m.hasArchitecture, out);
  _writeString(25, m.productName, out);
  _writeBool(26, m.hasProductName, out);
  _writeU64(27, m.cpuTimeMs, out);
  _writeBool(28, m.hasCpuTime, out);
  return out.toBytes();
}

Uint8List _encodeHealthVolume(HealthVolume m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.mountPoint, out);
  _writeString(3, m.label, out);
  _writeString(4, m.fileSystem, out);
  _writeU64(5, m.kind.index, out);
  _writeU64(6, m.usedBytes, out);
  _writeU64(7, m.totalBytes, out);
  _writeBool(8, m.hasCapacity, out);
  _writeBool(9, m.includedInSummary, out);
  return out.toBytes();
}

Uint8List _encodeHealthDiskHealth(HealthDiskHealth m) {
  final out = BytesBuilder();
  _writeU64(1, m.index, out);
  _writeString(2, m.model, out);
  _writeString(3, m.bus, out);
  _writeBool(4, m.hasTempC, out);
  _writeDouble(5, m.tempC, out);
  _writeBool(6, m.hasFailurePredicted, out);
  _writeBool(7, m.failurePredicted, out);
  _writeBool(8, m.hasCriticalWarning, out);
  _writeU64(9, m.criticalWarning, out);
  _writeBool(10, m.hasPercentageUsed, out);
  _writeU64(11, m.percentageUsed, out);
  _writeBool(12, m.hasAvailableSpare, out);
  _writeU64(13, m.availableSpare, out);
  _writeU64(14, m.availableSpareThreshold, out);
  _writeBool(15, m.hasPowerOnHours, out);
  _writeU64(16, m.powerOnHours, out);
  _writeBool(17, m.hasUnsafeShutdowns, out);
  _writeU64(18, m.unsafeShutdowns, out);
  _writeBool(19, m.hasMediaErrors, out);
  _writeU64(20, m.mediaErrors, out);
  _writeBool(21, m.hasBytesRead, out);
  _writeU64(22, m.bytesRead, out);
  _writeBool(23, m.hasBytesWritten, out);
  _writeU64(24, m.bytesWritten, out);
  return out.toBytes();
}
Uint8List _encodeHealthGpuAdapter(HealthGpuAdapter m) {
  final out = BytesBuilder();
  _writeU64(1, m.luidHigh, out);
  _writeU64(2, m.luidLow, out);
  _writeString(3, m.name, out);
  _writeString(4, m.vendor, out);
  _writeBool(5, m.isPrimary, out);
  _writeU64(6, m.dedicatedTotalBytes, out);
  _writeU64(7, m.sharedTotalBytes, out);
  _writeBool(8, m.hasPercent, out);
  _writeDouble(9, m.percent, out);
  _writeBool(10, m.hasDedicatedUsed, out);
  _writeU64(11, m.dedicatedUsedBytes, out);
  _writeBool(12, m.hasSharedUsed, out);
  _writeU64(13, m.sharedUsedBytes, out);
  return out.toBytes();
}

Uint8List _encodeHealthPhysicalDisk(HealthPhysicalDisk m) {
  final out = BytesBuilder();
  _writeString(1, m.id, out);
  _writeString(2, m.name, out);
  _writeBool(3, m.hasReadBps, out);
  _writeDouble(4, m.readBps, out);
  _writeBool(5, m.hasWriteBps, out);
  _writeDouble(6, m.writeBps, out);
  return out.toBytes();
}

Uint8List _encodeHealthStaticInfo(HealthStaticInfo m) {
  final out = BytesBuilder();
  _writeString(1, m.windowsEdition, out);
  _writeString(2, m.windowsVersion, out);
  _writeString(3, m.cpuModel, out);
  _writeString(4, m.gpuModel, out);
  _writeU64(5, m.installedRamBytes, out);
  _writeU64(6, m.primaryStorageBytes, out);
  _writeString(7, m.activeNetworkAdapter, out);
  _writeU64(8, m.cpuBaseMhz, out);
  _writeU64(9, m.cpuSockets, out);
  _writeU64(10, m.cpuCores, out);
  _writeU64(11, m.cpuLogicalProcessors, out);
  _writeBool(12, m.cpuVirtualizationEnabled, out);
  _writeU64(13, m.gpuDedicatedBytes, out);
  _writeU64(14, m.gpuSharedBytes, out);
  _writeString(15, m.cpuArchitecture, out);
  _writeString(16, m.cpuInstructionSet, out);
  _writeU64(17, m.cpuNumaNodes, out);
  _writeBool(18, m.hasCpuSmt, out);
  _writeBool(19, m.cpuSmtEnabled, out);
  _writeBool(20, m.hasCpuL1Cache, out);
  _writeU64(21, m.cpuL1CacheBytes, out);
  _writeBool(22, m.hasCpuL2Cache, out);
  _writeU64(23, m.cpuL2CacheBytes, out);
  _writeBool(24, m.hasCpuL3Cache, out);
  _writeU64(25, m.cpuL3CacheBytes, out);
  _writeString(26, m.cpuVirtualizationVendor, out);
  _writeString(27, m.gpuVendor, out);
  _writeString(28, m.gpuDriverVersion, out);
  _writeString(29, m.gpuDriverDate, out);
  _writeBool(30, m.hasGpuLuid, out);
  _writeU64(31, m.gpuLuidHigh, out);
  _writeU64(32, m.gpuLuidLow, out);
  _writeString(33, m.gpuDirectxVersion, out);
  _writeString(34, m.gpuWddmVersion, out);
  _writeBool(35, m.hasGpuHardwareScheduling, out);
  _writeBool(36, m.gpuHardwareScheduling, out);
  _writeString(37, m.gpuPcieLinkSpeed, out);
  _writeString(38, m.gpuPcieLinkWidth, out);
  _writeString(39, m.netManufacturer, out);
  _writeString(40, m.netDescription, out);
  _writeString(41, m.netMacAddress, out);
  _writeString(42, m.netDriverVersion, out);
  _writeString(43, m.netDriverDate, out);
  _writeString(44, m.netConnectionType, out);
  _writeString(45, m.netDuplex, out);
  _writeBool(46, m.hasNetMtu, out);
  _writeU64(47, m.netMtu, out);
  _writeBool(48, m.hasNetIfIndex, out);
  _writeU64(49, m.netIfIndex, out);
  _writeBool(50, m.hasNetLinkSpeedBps, out);
  _writeU64(51, m.netLinkSpeedBps, out);
  _writeBool(52, m.hasNetDhcp, out);
  _writeBool(53, m.netDhcpEnabled, out);
  _writeString(54, m.netDhcpServer, out);
  _writeBool(55, m.hasNetLeaseObtained, out);
  _writeU64(56, m.netLeaseObtainedUnixMs, out);
  _writeBool(57, m.hasNetLeaseExpires, out);
  _writeU64(58, m.netLeaseExpiresUnixMs, out);
  _writeBool(59, m.hasMemSlotsUsed, out);
  _writeU64(60, m.memSlotsUsed, out);
  _writeBool(61, m.hasMemModuleCount, out);
  _writeU64(62, m.memModuleCount, out);
  _writeString(63, m.memDdrGeneration, out);
  _writeBool(64, m.hasMemSpeedMhz, out);
  _writeU64(65, m.memSpeedMhz, out);
  _writeString(66, m.memFormFactor, out);
  _writeBool(67, m.hasMemEcc, out);
  _writeBool(68, m.memEcc, out);
  _writeBool(69, m.hasMemChannels, out);
  _writeU64(70, m.memChannels, out);
  _writeString(71, m.memDimmVendor, out);
  _writeString(72, m.memDimmPartNumber, out);
  _writeString(73, m.memDimmSerial, out);
  _writeString(74, m.diskInterface, out);
  _writeString(75, m.diskBus, out);
  _writeString(76, m.diskModel, out);
  _writeString(77, m.diskSerial, out);
  _writeString(78, m.diskFirmware, out);
  _writeString(79, m.diskPartitionStyle, out);
  _writeBool(80, m.hasDiskSectorSize, out);
  _writeU64(81, m.diskSectorSize, out);
  _writeBool(82, m.hasDiskRotationRate, out);
  _writeU64(83, m.diskRotationRate, out);
  _writeBool(84, m.hasDiskTrim, out);
  _writeBool(85, m.diskTrimSupported, out);
  _writeString(86, m.gpuPciLocation, out);
  _writeBool(87, m.hasGpuResizableBar, out);
  _writeBool(88, m.gpuResizableBar, out);
  return out.toBytes();
}

Uint8List _encodeHealthSample(HealthSample m) {
  final out = BytesBuilder();
  _writeU64(1, m.unixMs, out);
  _writeBool(2, m.hasCpuPercent, out);
  _writeDouble(3, m.cpuPercent, out);
  _writeU64(4, m.memoryUsedBytes, out);
  _writeU64(5, m.memoryTotalBytes, out);
  _writeBool(6, m.hasGpuPercent, out);
  _writeDouble(7, m.gpuPercent, out);
  _writeBool(8, m.hasNetDownloadBps, out);
  _writeDouble(9, m.netDownloadBps, out);
  _writeBool(10, m.hasNetUploadBps, out);
  _writeDouble(11, m.netUploadBps, out);
  _writeBool(12, m.hasDiskReadBps, out);
  _writeDouble(13, m.diskReadBps, out);
  _writeBool(14, m.hasDiskWriteBps, out);
  _writeDouble(15, m.diskWriteBps, out);
  _writeU64(16, m.diskUsedBytes, out);
  _writeU64(17, m.diskTotalBytes, out);
  _writeU64(18, m.uptimeMs, out);
  _writeBool(19, m.hasCpuTempC, out);
  _writeDouble(20, m.cpuTempC, out);
  _writeBool(21, m.hasGpuTempC, out);
  _writeDouble(22, m.gpuTempC, out);
  _writeBool(23, m.hasSsdTempC, out);
  _writeDouble(24, m.ssdTempC, out);
  _writeBool(25, m.hasCpuCurrentMhz, out);
  _writeDouble(26, m.cpuCurrentMhz, out);
  _writeU64(27, m.memoryAvailableBytes, out);
  _writeBool(28, m.hasMemoryCommitted, out);
  _writeU64(29, m.memoryCommittedBytes, out);
  _writeU64(30, m.memoryCommitLimitBytes, out);
  _writeBool(31, m.hasMemoryCached, out);
  _writeU64(32, m.memoryCachedBytes, out);
  _writeString(33, m.ipv4, out);
  _writeString(34, m.ipv6, out);
  _writeString(35, m.gateway, out);
  _writeString(36, m.dns, out);
  for (final e in m.topCpu) {
    _writeBytesField(37, _encodeHealthProcessEntry(e), out);
  }
  for (final e in m.topMemory) {
    _writeBytesField(38, _encodeHealthProcessEntry(e), out);
  }
  for (final e in m.topGpu) {
    _writeBytesField(39, _encodeHealthProcessEntry(e), out);
  }
  for (final e in m.topDisk) {
    _writeBytesField(40, _encodeHealthProcessEntry(e), out);
  }
  for (final e in m.topNetwork) {
    _writeBytesField(41, _encodeHealthProcessEntry(e), out);
  }
  for (final core in m.cpuCorePercent) {
    _writeDouble(42, core, out);
  }
  for (final v in m.volumes) {
    _writeBytesField(43, _encodeHealthVolume(v), out);
  }
  for (final d in m.disks) {
    _writeBytesField(44, _encodeHealthPhysicalDisk(d), out);
  }
  _writeBool(45, m.hasMemoryCompressed, out);
  _writeU64(46, m.memoryCompressedBytes, out);
  _writeBool(47, m.hasMemoryHardwareReserved, out);
  _writeU64(48, m.memoryHardwareReservedBytes, out);
  _writeBool(49, m.hasMemoryPagedPool, out);
  _writeU64(50, m.memoryPagedPoolBytes, out);
  _writeBool(51, m.hasMemoryNonpagedPool, out);
  _writeU64(52, m.memoryNonpagedPoolBytes, out);
  _writeBool(53, m.hasMemoryPageFaultsPerSec, out);
  _writeDouble(54, m.memoryPageFaultsPerSec, out);
  _writeBool(55, m.hasGpuUtil3d, out);
  _writeDouble(56, m.gpuUtil3d, out);
  _writeBool(57, m.hasGpuUtilCompute, out);
  _writeDouble(58, m.gpuUtilCompute, out);
  _writeBool(59, m.hasGpuUtilCopy, out);
  _writeDouble(60, m.gpuUtilCopy, out);
  _writeBool(61, m.hasGpuUtilVideoDecode, out);
  _writeDouble(62, m.gpuUtilVideoDecode, out);
  _writeBool(63, m.hasGpuUtilVideoEncode, out);
  _writeDouble(64, m.gpuUtilVideoEncode, out);
  _writeBool(65, m.hasGpuDedicatedUsed, out);
  _writeU64(66, m.gpuDedicatedUsedBytes, out);
  _writeBool(67, m.hasGpuSharedUsed, out);
  _writeU64(68, m.gpuSharedUsedBytes, out);
  _writeBool(69, m.hasGpuClockMhz, out);
  _writeDouble(70, m.gpuClockMhz, out);
  _writeBool(71, m.hasGpuMemoryClockMhz, out);
  _writeDouble(72, m.gpuMemoryClockMhz, out);
  _writeBool(73, m.hasGpuFanRpm, out);
  _writeDouble(74, m.gpuFanRpm, out);
  _writeBool(75, m.hasGpuPowerPercent, out);
  _writeDouble(76, m.gpuPowerPercent, out);
  _writeBool(77, m.hasNetPeakDownloadBps, out);
  _writeDouble(78, m.netPeakDownloadBps, out);
  _writeBool(79, m.hasNetPeakUploadBps, out);
  _writeDouble(80, m.netPeakUploadBps, out);
  _writeBool(81, m.hasNetAvgDownloadBps, out);
  _writeDouble(82, m.netAvgDownloadBps, out);
  _writeBool(83, m.hasNetAvgUploadBps, out);
  _writeDouble(84, m.netAvgUploadBps, out);
  _writeBool(85, m.hasNetUtilizationPercent, out);
  _writeDouble(86, m.netUtilizationPercent, out);
  _writeBool(87, m.hasNetConnectionMs, out);
  _writeU64(88, m.netConnectionMs, out);
  _writeBool(89, m.hasNetBytesSent, out);
  _writeU64(90, m.netBytesSent, out);
  _writeBool(91, m.hasNetBytesReceived, out);
  _writeU64(92, m.netBytesReceived, out);
  _writeBool(93, m.hasNetPacketsSent, out);
  _writeU64(94, m.netPacketsSent, out);
  _writeBool(95, m.hasNetPacketsReceived, out);
  _writeU64(96, m.netPacketsReceived, out);
  _writeBool(97, m.hasNetErrors, out);
  _writeU64(98, m.netErrors, out);
  _writeBool(99, m.hasNetDrops, out);
  _writeU64(100, m.netDrops, out);
  _writeString(101, m.netSsid, out);
  _writeBool(102, m.hasNetSignalPercent, out);
  _writeDouble(103, m.netSignalPercent, out);
  _writeString(104, m.netWifiChannel, out);
  _writeString(105, m.netWifiFrequency, out);
  _writeString(106, m.netWifiSecurity, out);
  _writeBool(107, m.hasGpuUtilVideoProcessing, out);
  _writeDouble(108, m.gpuUtilVideoProcessing, out);
  _writeBool(109, m.hasDiskPowerOnHours, out);
  _writeU64(110, m.diskPowerOnHours, out);
  _writeBool(111, m.hasDiskTotalBytesWritten, out);
  _writeU64(112, m.diskTotalBytesWritten, out);
  _writeBool(113, m.hasDiskTotalBytesRead, out);
  _writeU64(114, m.diskTotalBytesRead, out);
  _writeBool(115, m.hasDiskSmartOk, out);
  _writeBool(116, m.diskSmartOk, out);
  for (final d in m.diskHealth) {
    _writeBytesField(117, _encodeHealthDiskHealth(d), out);
  }
  for (final g in m.gpus) {
    _writeBytesField(118, _encodeHealthGpuAdapter(g), out);
  }
  return out.toBytes();
}

Uint8List _encodeGetHealthSnapshot(GetHealthSnapshot _) {
  return Uint8List(0);
}

Uint8List _encodeHealthSnapshot(HealthSnapshot m) {
  final out = BytesBuilder();
  _writeBytesField(1, _encodeHealthStaticInfo(m.info), out);
  _writeBytesField(2, _encodeHealthSample(m.sample), out);
  return out.toBytes();
}

Uint8List _encodeHealthUpdate(HealthUpdate m) {
  final out = BytesBuilder();
  _writeBytesField(1, _encodeHealthSample(m.sample), out);
  final processInventory = m.processInventory;
  if (processInventory != null) {
    _writeBytesField(
      2,
      _encodeHealthProcessInventoryUpdate(processInventory),
      out,
    );
  }
  return out.toBytes();
}

Uint8List _encodeStartHealthMonitoring(StartHealthMonitoring _) {
  return Uint8List(0);
}

Uint8List _encodeStopHealthMonitoring(StopHealthMonitoring _) {
  return Uint8List(0);
}

Uint8List _encodeGetDiagnosticsSnapshot(GetDiagnosticsSnapshot _) {
  return Uint8List(0);
}

Uint8List _encodeDiagnosticsSnapshot(DiagnosticsSnapshot m) {
  final out = BytesBuilder();
  _writeString(1, m.serviceVersion, out);
  _writeU64(2, m.protocolVersion, out);
  _writeU64(3, m.serviceStartUnixMs, out);
  _writeU64(4, m.serviceUptimeMs, out);
  _writeString(5, m.runMode, out);
  _writeBool(6, m.ipcListening, out);

  _writeBool(7, m.liveSubscribed, out);
  _writeString(8, m.liveChannel, out);
  _writeU64(9, m.liveEventsPushed, out);
  _writeU64(10, m.liveEventsDropped, out);
  _writeU64(11, m.liveSubscriberReconnects, out);
  _writeU64(12, m.lastLiveEventUnixMs, out);
  _writeString(13, m.lastLiveEventTitle, out);
  _writeU64(14, m.liveQueueDepth, out);
  _writeU64(15, m.liveQueueCapacity, out);

  _writeU64(16, m.ipcMessagesReceived, out);
  _writeU64(17, m.ipcMessagesSent, out);
  _writeU64(18, m.ipcErrors, out);
  _writeU64(19, m.connectedClients, out);

  _writeU64(20, m.servicePid, out);
  _writeBool(21, m.hasCpuPercent, out);
  _writeDouble(22, m.cpuPercent, out);
  _writeU64(23, m.workingSetBytes, out);
  _writeU64(24, m.threadCount, out);
  _writeU64(25, m.handleCount, out);

  _writeU64(26, m.stageEventLog, out);
  _writeU64(27, m.stageCollector, out);
  _writeU64(28, m.stageIntelligence, out);
  _writeU64(29, m.stageIpc, out);
  _writeString(30, m.stageDetail, out);

  _writeString(31, m.windowsEdition, out);
  _writeString(32, m.windowsVersion, out);

  _writeString(33, m.executablePath, out);
  _writeString(34, m.buildVersion, out);
  _writeString(35, m.gitCommit, out);
  _writeString(36, m.binarySha256, out);
  _writeString(37, m.installPath, out);
  _writeBool(38, m.hasPathsMatch, out);
  _writeBool(39, m.pathsMatch, out);
  _writeString(40, m.scmState, out);
  _writeString(41, m.scmStartupType, out);

  _writeU64(42, m.ipcBytesReceived, out);
  _writeU64(43, m.ipcBytesSent, out);
  _writeBool(44, m.hasIpcMessagesPerSec, out);
  _writeDouble(45, m.ipcMessagesPerSec, out);
  _writeBool(46, m.hasIpcBytesPerSec, out);
  _writeDouble(47, m.ipcBytesPerSec, out);

  _writeBool(48, m.healthMonitoringActive, out);
  _writeDouble(49, m.healthSampleRateHz, out);
  _writeBool(50, m.networkEtwRunning, out);
  _writeString(51, m.networkEtwLastError, out);

  _writeString(52, m.stageEventLogDetail, out);
  _writeString(53, m.stageCollectorDetail, out);
  _writeString(54, m.stageIntelligenceDetail, out);
  _writeString(55, m.stageIpcDetail, out);
  return out.toBytes();
}

Uint8List _encodeInjectDiagnosticsTestEvent(InjectDiagnosticsTestEvent _) {
  return Uint8List(0);
}

void _writeBytesField(int field, Uint8List bytes, BytesBuilder out) {
  _writeTag(field, 2, out);
  _writeVarint(bytes.length, out);
  out.add(bytes);
}

Uint8List _encodeCrashOccurrence(CrashOccurrence m) {
  final out = BytesBuilder();
  _writeU64(1, m.timestampUnixMs, out);
  _writeString(2, m.channel, out);
  _writeU64(3, m.recordId, out);
  _writeString(4, m.version, out);
  return out.toBytes();
}

Uint8List _encodeCrashVersion(CrashVersion m) {
  final out = BytesBuilder();
  _writeString(1, m.version, out);
  _writeU64(2, m.count, out);
  _writeU64(3, m.lastUnixMs, out);
  return out.toBytes();
}

Uint8List _encodeCrashGroup(CrashGroup m) {
  final out = BytesBuilder();
  _writeU64(1, m.kind.index, out);
  _writeString(2, m.key, out);
  _writeString(3, m.subject, out);
  _writeString(4, m.moduleName, out);
  _writeString(5, m.modulePath, out);
  _writeString(6, m.moduleCompany, out);
  _writeU64(7, m.moduleOrigin.index, out);
  _writeU64(8, m.code, out);
  _writeBool(9, m.hasCode, out);
  _writeString(10, m.title, out);
  _writeString(11, m.summary, out);
  _writeString(12, m.recommendation, out);
  _writeU64(13, m.count, out);
  _writeU64(14, m.firstUnixMs, out);
  _writeU64(15, m.lastUnixMs, out);
  for (final unixMs in m.occurrenceUnixMs) {
    _writeU64(16, unixMs, out);
  }
  for (final version in m.versions) {
    _writeBytesField(17, _encodeCrashVersion(version), out);
  }
  for (final occurrence in m.recent) {
    _writeBytesField(18, _encodeCrashOccurrence(occurrence), out);
  }
  return out.toBytes();
}

Uint8List _encodeGetCrashHistory(GetCrashHistory m) {
  final out = BytesBuilder();
  _writeU64(1, m.days, out);
  return out.toBytes();
}

Uint8List _encodeCrashHistory(CrashHistory m) {
  final out = BytesBuilder();
  _writeU64(1, m.days, out);
  _writeU64(2, m.collectedUnixMs, out);
  for (final group in m.groups) {
    _writeBytesField(3, _encodeCrashGroup(group), out);
  }
  _writeU64(4, m.scannedEvents, out);
  _writeBool(5, m.truncated, out);
  for (final channel in m.unreadableChannels) {
    _writeString(6, channel, out);
  }
  return out.toBytes();
}

Uint8List _encodeEventLogChannelInfo(EventLogChannelInfo m) {
  final out = BytesBuilder();
  _writeString(1, m.path, out);
  _writeU64(2, m.type.index, out);
  _writeBool(3, m.enabled, out);
  _writeU64(4, m.access.index, out);
  _writeU64(5, m.recordCount, out);
  _writeBool(6, m.hasRecordCount, out);
  _writeBool(7, m.builtIn, out);
  _writeBool(8, m.tracked, out);
  _writeString(9, m.detail, out);
  return out.toBytes();
}

Uint8List _encodeEventLogChannelList(EventLogChannelList m) {
  final out = BytesBuilder();
  for (final channel in m.channels) {
    _writeBytesField(1, _encodeEventLogChannelInfo(channel), out);
  }
  _writeU64(2, m.collectedUnixMs, out);
  _writeU64(3, m.maxTracked, out);
  _writeU64(4, m.skippedChannels, out);
  return out.toBytes();
}

Uint8List _encodeSetTrackedChannels(SetTrackedChannels m) {
  final out = BytesBuilder();
  for (final channel in m.channels) {
    _writeString(1, channel, out);
  }
  return out.toBytes();
}

Uint8List _encodeTrackedChannelResult(TrackedChannelResult m) {
  final out = BytesBuilder();
  _writeString(1, m.path, out);
  _writeU64(2, m.status.index, out);
  _writeString(3, m.detail, out);
  return out.toBytes();
}

Uint8List _encodeTrackedChannels(TrackedChannels m) {
  final out = BytesBuilder();
  for (final result in m.results) {
    _writeBytesField(1, _encodeTrackedChannelResult(result), out);
  }
  _writeU64(2, m.maxTracked, out);
  for (final channel in m.tracked) {
    _writeString(3, channel, out);
  }
  return out.toBytes();
}

Uint8List encodeEnvelope(Envelope env) {
  final out = BytesBuilder();
  _writeU64(1, env.requestId, out);
  final body = env.body;
  if (body is ClientHello) {
    _writeBytesField(10, _encodeClientHello(body), out);
  } else if (body is ServerHello) {
    _writeBytesField(11, _encodeServerHello(body), out);
  } else if (body is Ping) {
    _writeBytesField(12, _encodePing(body), out);
  } else if (body is Pong) {
    _writeBytesField(13, _encodePong(body), out);
  } else if (body is Heartbeat) {
    _writeBytesField(14, _encodeHeartbeat(body), out);
  } else if (body is GetTimelineSnapshot) {
    _writeBytesField(20, _encodeGetTimelineSnapshot(body), out);
  } else if (body is TimelineSnapshot) {
    _writeBytesField(21, _encodeTimelineSnapshot(body), out);
  } else if (body is TimelineEvent) {
    _writeBytesField(22, _encodeTimelineEvent(body), out);
  } else if (body is StartLiveMonitoring) {
    _writeBytesField(23, _encodeStartLiveMonitoring(body), out);
  } else if (body is StopLiveMonitoring) {
    _writeBytesField(24, _encodeStopLiveMonitoring(body), out);
  } else if (body is GetHealthSnapshot) {
    _writeBytesField(25, _encodeGetHealthSnapshot(body), out);
  } else if (body is HealthSnapshot) {
    _writeBytesField(26, _encodeHealthSnapshot(body), out);
  } else if (body is HealthUpdate) {
    _writeBytesField(27, _encodeHealthUpdate(body), out);
  } else if (body is StartHealthMonitoring) {
    _writeBytesField(28, _encodeStartHealthMonitoring(body), out);
  } else if (body is StopHealthMonitoring) {
    _writeBytesField(29, _encodeStopHealthMonitoring(body), out);
  } else if (body is GetDiagnosticsSnapshot) {
    _writeBytesField(30, _encodeGetDiagnosticsSnapshot(body), out);
  } else if (body is DiagnosticsSnapshot) {
    _writeBytesField(31, _encodeDiagnosticsSnapshot(body), out);
  } else if (body is InjectDiagnosticsTestEvent) {
    _writeBytesField(32, _encodeInjectDiagnosticsTestEvent(body), out);
  } else if (body is GetProcessDetails) {
    _writeBytesField(33, _encodeGetProcessDetails(body), out);
  } else if (body is ProcessDetails) {
    _writeBytesField(34, _encodeProcessDetails(body), out);
  } else if (body is GetTimelineEventDetail) {
    _writeBytesField(35, _encodeGetTimelineEventDetail(body), out);
  } else if (body is TimelineEventDetail) {
    _writeBytesField(36, _encodeTimelineEventDetail(body), out);
  } else if (body is GetInventoryDomain) {
    _writeBytesField(37, _encodeGetInventoryDomain(body), out);
  } else if (body is InventoryDomainSnapshot) {
    _writeBytesField(38, _encodeInventoryDomainSnapshot(body), out);
  } else if (body is GetCrashHistory) {
    _writeBytesField(39, _encodeGetCrashHistory(body), out);
  } else if (body is CrashHistory) {
    _writeBytesField(40, _encodeCrashHistory(body), out);
  } else if (body is ListEventLogChannels) {
    _writeBytesField(41, Uint8List(0), out);
  } else if (body is EventLogChannelList) {
    _writeBytesField(42, _encodeEventLogChannelList(body), out);
  } else if (body is SetTrackedChannels) {
    _writeBytesField(43, _encodeSetTrackedChannels(body), out);
  } else if (body is TrackedChannels) {
    _writeBytesField(44, _encodeTrackedChannels(body), out);
  } else if (body is ErrorResponse) {
    _writeBytesField(99, _encodeError(body), out);
  }
  return out.toBytes();
}

class _Reader {
  _Reader(this.data) : offset = 0;
  final Uint8List data;
  int offset;

  bool get hasMore => offset < data.length;

  int readVarint() {
    var result = 0;
    var shift = 0;
    while (offset < data.length) {
      final b = data[offset++];
      result |= (b & 0x7f) << shift;
      if ((b & 0x80) == 0) return result;
      shift += 7;
    }
    throw FormatException('truncated varint');
  }

  String readString() {
    final len = readVarint();
    if (len < 0 || offset + len > data.length) {
      throw FormatException('truncated string');
    }
    final bytes = data.sublist(offset, offset + len);
    offset += len;
    // Event Log text may contain legacy encodings; never fail the whole frame.
    return utf8.decode(bytes, allowMalformed: true);
  }

  Uint8List readBytes() {
    final len = readVarint();
    final bytes = data.sublist(offset, offset + len);
    offset += len;
    return bytes;
  }

  double readDouble() {
    if (offset + 8 > data.length) {
      throw FormatException('truncated double');
    }
    final bd = ByteData.sublistView(data, offset, offset + 8);
    offset += 8;
    return bd.getFloat64(0, Endian.little);
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        readVarint();
        break;
      case 1:
        offset += 8;
        break;
      case 2:
        final len = readVarint();
        offset += len;
        break;
      case 5:
        offset += 4;
        break;
      default:
        throw FormatException('unknown wire $wire');
    }
  }
}

ClientHello _decodeClientHello(Uint8List data) {
  final r = _Reader(data);
  final m = ClientHello();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.protocolVersion = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.clientName = r.readString();
    } else if (field == 3 && wire == 2) {
      m.clientVersion = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

ServerHello _decodeServerHello(Uint8List data) {
  final r = _Reader(data);
  final m = ServerHello();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.protocolVersion = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.serviceVersion = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

Ping _decodePing(Uint8List data) {
  final r = _Reader(data);
  final m = Ping();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.nonce = r.readVarint();
    } else if (field == 2 && wire == 0) {
      m.unixMs = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

Pong _decodePong(Uint8List data) {
  final r = _Reader(data);
  final m = Pong();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.nonce = r.readVarint();
    } else if (field == 2 && wire == 0) {
      m.unixMs = r.readVarint();
    } else if (field == 3 && wire == 2) {
      m.serviceVersion = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

Heartbeat _decodeHeartbeat(Uint8List data) {
  final r = _Reader(data);
  final m = Heartbeat();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.unixMs = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

ErrorResponse _decodeError(Uint8List data) {
  final r = _Reader(data);
  final m = ErrorResponse();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.code = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.message = r.readString();
    } else if (field == 3 && wire == 2) {
      m.technicalDetail = r.readString();
    } else if (field == 4 && wire == 2) {
      m.component = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

TimelineEvent _decodeTimelineEvent(Uint8List data) {
  final r = _Reader(data);
  final m = TimelineEvent();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.eventId = r.readString();
    } else if (field == 2 && wire == 0) {
      m.timestampUnixMs = r.readVarint();
    } else if (field == 3 && wire == 2) {
      m.timestampIso = r.readString();
    } else if (field == 4 && wire == 0) {
      m.severity = r.readVarint();
    } else if (field == 5 && wire == 2) {
      m.channel = r.readString();
    } else if (field == 6 && wire == 2) {
      m.providerName = r.readString();
    } else if (field == 7 && wire == 0) {
      m.winEventId = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.recordId = r.readVarint();
    } else if (field == 9 && wire == 2) {
      m.computerName = r.readString();
    } else if (field == 10 && wire == 2) {
      m.summary = r.readString();
    } else if (field == 11 && wire == 2) {
      m.technicalSummary = r.readString();
    } else if (field == 12 && wire == 2) {
      m.message = r.readString();
    } else if (field == 13 && wire == 2) {
      m.title = r.readString();
    } else if (field == 14 && wire == 2) {
      m.recommendation = r.readString();
    } else if (field == 15 && wire == 0) {
      m.actionRequired = r.readVarint() != 0;
    } else if (field == 16 && wire == 0) {
      m.importance = r.readVarint();
    } else if (field == 17 && wire == 2) {
      m.category = r.readString();
    } else if (field == 18 && wire == 0) {
      m.task = r.readVarint();
    } else if (field == 19 && wire == 0) {
      m.hasTask = r.readVarint() != 0;
    } else if (field == 20 && wire == 0) {
      m.opcode = r.readVarint();
    } else if (field == 21 && wire == 0) {
      m.hasOpcode = r.readVarint() != 0;
    } else if (field == 22 && wire == 0) {
      m.keywords = r.readVarint();
    } else if (field == 23 && wire == 0) {
      m.hasKeywords = r.readVarint() != 0;
    } else if (field == 24 && wire == 0) {
      m.processId = r.readVarint();
    } else if (field == 25 && wire == 0) {
      m.hasProcessId = r.readVarint() != 0;
    } else if (field == 26 && wire == 2) {
      m.processName = r.readString();
    } else if (field == 27 && wire == 0) {
      m.threadId = r.readVarint();
    } else if (field == 28 && wire == 0) {
      m.hasThreadId = r.readVarint() != 0;
    } else if (field == 29 && wire == 2) {
      m.userSid = r.readString();
    } else if (field == 30 && wire == 2) {
      m.activityId = r.readString();
    } else if (field == 31 && wire == 2) {
      m.relatedActivityId = r.readString();
    } else if (field == 32 && wire == 2) {
      m.levelName = r.readString();
    } else if (field == 33 && wire == 2) {
      m.rawXml = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

GetTimelineEventDetail _decodeGetTimelineEventDetail(Uint8List data) {
  final r = _Reader(data);
  final m = GetTimelineEventDetail();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.channel = r.readString();
    } else if (field == 2 && wire == 0) {
      m.recordId = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

TimelineEventDetail _decodeTimelineEventDetail(Uint8List data) {
  final r = _Reader(data);
  final m = TimelineEventDetail();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.found = r.readVarint() != 0;
    } else if (field == 2 && wire == 2) {
      m.event = _decodeTimelineEvent(r.readBytes());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryDomainId _inventoryDomainIdFromWire(int v) {
  if (v < 0 || v >= InventoryDomainId.values.length) {
    return InventoryDomainId.unspecified;
  }
  return InventoryDomainId.values[v];
}

InventoryStatus _inventoryStatusFromWire(int v) {
  if (v < 0 || v >= InventoryStatus.values.length) {
    return InventoryStatus.unspecified;
  }
  return InventoryStatus.values[v];
}

InventoryServiceEntry _decodeInventoryServiceEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryServiceEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.displayName = r.readString();
    } else if (field == 3 && wire == 2) {
      m.state = r.readString();
    } else if (field == 4 && wire == 2) {
      m.startType = r.readString();
    } else if (field == 5 && wire == 2) {
      m.account = r.readString();
    } else if (field == 6 && wire == 2) {
      m.binaryPath = r.readString();
    } else if (field == 7 && wire == 2) {
      m.description = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryDriverEntry _decodeInventoryDriverEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryDriverEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.displayName = r.readString();
    } else if (field == 3 && wire == 2) {
      m.state = r.readString();
    } else if (field == 4 && wire == 2) {
      m.startType = r.readString();
    } else if (field == 5 && wire == 2) {
      m.binaryPath = r.readString();
    } else if (field == 6 && wire == 2) {
      m.description = r.readString();
    } else if (field == 7 && wire == 2) {
      m.driverType = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventorySoftwareEntry _decodeInventorySoftwareEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventorySoftwareEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.displayName = r.readString();
    } else if (field == 3 && wire == 2) {
      m.version = r.readString();
    } else if (field == 4 && wire == 2) {
      m.publisher = r.readString();
    } else if (field == 5 && wire == 2) {
      m.installDate = r.readString();
    } else if (field == 6 && wire == 2) {
      m.installLocation = r.readString();
    } else if (field == 7 && wire == 0) {
      m.estimatedSizeBytes = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.hasEstimatedSize = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.systemComponent = r.readVarint() != 0;
    } else if (field == 10 && wire == 2) {
      m.architecture = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryUsbEntry _decodeInventoryUsbEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryUsbEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.description = r.readString();
    } else if (field == 3 && wire == 2) {
      m.hardwareId = r.readString();
    } else if (field == 4 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 5 && wire == 2) {
      m.service = r.readString();
    } else if (field == 6 && wire == 2) {
      m.className = r.readString();
    } else if (field == 7 && wire == 2) {
      m.classGuid = r.readString();
    } else if (field == 8 && wire == 0) {
      m.problemCode = r.readVarint();
    } else if (field == 9 && wire == 0) {
      m.hasProblemCode = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryPciEntry _decodeInventoryPciEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryPciEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.description = r.readString();
    } else if (field == 3 && wire == 2) {
      m.hardwareId = r.readString();
    } else if (field == 4 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 5 && wire == 2) {
      m.service = r.readString();
    } else if (field == 6 && wire == 2) {
      m.className = r.readString();
    } else if (field == 7 && wire == 2) {
      m.classGuid = r.readString();
    } else if (field == 8 && wire == 2) {
      m.locationInfo = r.readString();
    } else if (field == 9 && wire == 0) {
      m.problemCode = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasProblemCode = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryPnPDeviceEntry _decodeInventoryPnPDeviceEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryPnPDeviceEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.description = r.readString();
    } else if (field == 3 && wire == 2) {
      m.hardwareId = r.readString();
    } else if (field == 4 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 5 && wire == 2) {
      m.service = r.readString();
    } else if (field == 6 && wire == 2) {
      m.className = r.readString();
    } else if (field == 7 && wire == 2) {
      m.classGuid = r.readString();
    } else if (field == 8 && wire == 2) {
      m.locationInfo = r.readString();
    } else if (field == 9 && wire == 0) {
      m.problemCode = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasProblemCode = r.readVarint() != 0;
    } else if (field == 11 && wire == 2) {
      m.adapterName = r.readString();
    } else if (field == 12 && wire == 0) {
      m.descriptionFromEnumDisplay = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryPrinterEntry _decodeInventoryPrinterEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryPrinterEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.portName = r.readString();
    } else if (field == 3 && wire == 2) {
      m.driverName = r.readString();
    } else if (field == 4 && wire == 2) {
      m.location = r.readString();
    } else if (field == 5 && wire == 2) {
      m.comment = r.readString();
    } else if (field == 6 && wire == 0) {
      m.isShared = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.isDefault = r.readVarint() != 0;
    } else if (field == 8 && wire == 0) {
      m.isNetwork = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.attributes = r.readVarint();
      m.hasAttributes = true;
    } else if (field == 10 && wire == 0) {
      m.hasAttributes = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryBatteryEntry _decodeInventoryBatteryEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryBatteryEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.description = r.readString();
    } else if (field == 3 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 4 && wire == 2) {
      m.chemistry = r.readString();
    } else if (field == 5 && wire == 0) {
      m.designCapacityMwh = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.hasDesignCapacity = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.fullChargedCapacityMwh = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.hasFullChargedCapacity = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.cycleCount = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasCycleCount = r.readVarint() != 0;
    } else if (field == 11 && wire == 0) {
      m.capacityPercent = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.hasCapacityPercent = r.readVarint() != 0;
    } else if (field == 13 && wire == 2) {
      m.powerState = r.readString();
    } else if (field == 14 && wire == 0) {
      m.fromSystemPowerFallback = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryMotherboardEntry _decodeInventoryMotherboardEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryMotherboardEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 3 && wire == 2) {
      m.product = r.readString();
    } else if (field == 4 && wire == 2) {
      m.version = r.readString();
    } else if (field == 5 && wire == 2) {
      m.serialNumber = r.readString();
    } else if (field == 6 && wire == 2) {
      m.assetTag = r.readString();
    } else if (field == 7 && wire == 2) {
      m.locationInChassis = r.readString();
    } else if (field == 8 && wire == 2) {
      m.boardType = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryBiosEntry _decodeInventoryBiosEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryBiosEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.vendor = r.readString();
    } else if (field == 3 && wire == 2) {
      m.version = r.readString();
    } else if (field == 4 && wire == 2) {
      m.releaseDate = r.readString();
    } else if (field == 5 && wire == 0) {
      m.majorRelease = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.hasMajorRelease = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.minorRelease = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.hasMinorRelease = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.romSizeBytes = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasRomSizeBytes = r.readVarint() != 0;
    } else if (field == 11 && wire == 0) {
      m.uefiCapable = r.readVarint() != 0;
    } else if (field == 12 && wire == 0) {
      m.hasUefiCapable = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryCpuEntry _decodeInventoryCpuEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryCpuEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.name = r.readString();
    } else if (field == 3 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 4 && wire == 2) {
      m.architecture = r.readString();
    } else if (field == 5 && wire == 0) {
      m.sockets = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.hasSockets = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.physicalCores = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.hasPhysicalCores = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.logicalProcessors = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasLogicalProcessors = r.readVarint() != 0;
    } else if (field == 11 && wire == 0) {
      m.baseClockMhz = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.hasBaseClockMhz = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.numaNodes = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.hasNumaNodes = r.readVarint() != 0;
    } else if (field == 15 && wire == 0) {
      m.l1CacheBytes = r.readVarint();
    } else if (field == 16 && wire == 0) {
      m.hasL1CacheBytes = r.readVarint() != 0;
    } else if (field == 17 && wire == 0) {
      m.l2CacheBytes = r.readVarint();
    } else if (field == 18 && wire == 0) {
      m.hasL2CacheBytes = r.readVarint() != 0;
    } else if (field == 19 && wire == 0) {
      m.l3CacheBytes = r.readVarint();
    } else if (field == 20 && wire == 0) {
      m.hasL3CacheBytes = r.readVarint() != 0;
    } else if (field == 21 && wire == 2) {
      m.instructionSet = r.readString();
    } else if (field == 22 && wire == 0) {
      m.smtEnabled = r.readVarint() != 0;
    } else if (field == 23 && wire == 0) {
      m.hasSmtEnabled = r.readVarint() != 0;
    } else if (field == 24 && wire == 2) {
      m.virtualizationVendor = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryMemoryModuleEntry _decodeInventoryMemoryModuleEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryMemoryModuleEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.bankLocator = r.readString();
    } else if (field == 3 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 4 && wire == 2) {
      m.partNumber = r.readString();
    } else if (field == 5 && wire == 2) {
      m.serialNumber = r.readString();
    } else if (field == 6 && wire == 0) {
      m.sizeBytes = r.readVarint();
    } else if (field == 7 && wire == 0) {
      m.hasSizeBytes = r.readVarint() != 0;
    } else if (field == 8 && wire == 0) {
      m.speedMts = r.readVarint();
    } else if (field == 9 && wire == 0) {
      m.hasSpeedMts = r.readVarint() != 0;
    } else if (field == 10 && wire == 0) {
      m.configuredSpeedMts = r.readVarint();
    } else if (field == 11 && wire == 0) {
      m.hasConfiguredSpeedMts = r.readVarint() != 0;
    } else if (field == 12 && wire == 2) {
      m.formFactor = r.readString();
    } else if (field == 13 && wire == 2) {
      m.memoryType = r.readString();
    } else if (field == 14 && wire == 0) {
      m.isEcc = r.readVarint() != 0;
    } else if (field == 15 && wire == 0) {
      m.hasIsEcc = r.readVarint() != 0;
    } else if (field == 16 && wire == 0) {
      m.totalWidthBits = r.readVarint();
    } else if (field == 17 && wire == 0) {
      m.hasTotalWidthBits = r.readVarint() != 0;
    } else if (field == 18 && wire == 0) {
      m.dataWidthBits = r.readVarint();
    } else if (field == 19 && wire == 0) {
      m.hasDataWidthBits = r.readVarint() != 0;
    } else if (field == 20 && wire == 0) {
      m.configuredVoltageMv = r.readVarint();
    } else if (field == 21 && wire == 0) {
      m.hasConfiguredVoltageMv = r.readVarint() != 0;
    } else if (field == 22 && wire == 0) {
      m.populated = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryStorageEntry _decodeInventoryStorageEntry(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryStorageEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.devicePath = r.readString();
    } else if (field == 3 && wire == 0) {
      m.physicalDriveNumber = r.readVarint();
    } else if (field == 4 && wire == 0) {
      m.hasPhysicalDriveNumber = r.readVarint() != 0;
    } else if (field == 5 && wire == 2) {
      m.model = r.readString();
    } else if (field == 6 && wire == 2) {
      m.vendor = r.readString();
    } else if (field == 7 && wire == 2) {
      m.serialNumber = r.readString();
    } else if (field == 8 && wire == 2) {
      m.firmwareRevision = r.readString();
    } else if (field == 9 && wire == 2) {
      m.busType = r.readString();
    } else if (field == 10 && wire == 2) {
      m.mediaType = r.readString();
    } else if (field == 11 && wire == 0) {
      m.sizeBytes = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.hasSizeBytes = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.sectorSizeBytes = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.hasSectorSizeBytes = r.readVarint() != 0;
    } else if (field == 15 && wire == 2) {
      m.partitionStyle = r.readString();
    } else if (field == 16 && wire == 0) {
      m.isRemovable = r.readVarint() != 0;
    } else if (field == 17 && wire == 0) {
      m.hasIsRemovable = r.readVarint() != 0;
    } else if (field == 18 && wire == 0) {
      m.trimSupported = r.readVarint() != 0;
    } else if (field == 19 && wire == 0) {
      m.hasTrimSupported = r.readVarint() != 0;
    } else if (field == 20 && wire == 2) {
      m.manufacturer = r.readString();
    } else if (field == 21 && wire == 2) {
      m.description = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryNetworkAdapterEntry _decodeInventoryNetworkAdapterEntry(
    Uint8List data) {
  final r = _Reader(data);
  final m = InventoryNetworkAdapterEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.description = r.readString();
    } else if (field == 3 && wire == 2) {
      m.friendlyName = r.readString();
    } else if (field == 4 && wire == 2) {
      m.macAddress = r.readString();
    } else if (field == 5 && wire == 2) {
      m.connectionType = r.readString();
    } else if (field == 6 && wire == 0) {
      m.ifIndex = r.readVarint();
    } else if (field == 7 && wire == 0) {
      m.hasIfIndex = r.readVarint() != 0;
    } else if (field == 8 && wire == 0) {
      m.mtu = r.readVarint();
    } else if (field == 9 && wire == 0) {
      m.hasMtu = r.readVarint() != 0;
    } else if (field == 10 && wire == 2) {
      m.operationalStatus = r.readString();
    } else if (field == 11 && wire == 0) {
      m.dhcpEnabled = r.readVarint() != 0;
    } else if (field == 12 && wire == 0) {
      m.hasDhcpEnabled = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.linkSpeedBps = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.hasLinkSpeedBps = r.readVarint() != 0;
    } else if (field == 15 && wire == 0) {
      m.isLoopback = r.readVarint() != 0;
    } else if (field == 16 && wire == 2) {
      m.ipv4Addresses.add(r.readString());
    } else if (field == 17 && wire == 2) {
      m.ipv6Addresses.add(r.readString());
    } else if (field == 18 && wire == 2) {
      m.gatewayAddresses.add(r.readString());
    } else if (field == 19 && wire == 2) {
      m.dnsAddresses.add(r.readString());
    } else if (field == 20 && wire == 2) {
      m.driverProvider = r.readString();
    } else if (field == 21 && wire == 2) {
      m.driverVersion = r.readString();
    } else if (field == 22 && wire == 2) {
      m.driverDate = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

GetInventoryDomain _decodeGetInventoryDomain(Uint8List data) {
  final r = _Reader(data);
  final m = GetInventoryDomain();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.domain = _inventoryDomainIdFromWire(r.readVarint());
    } else if (field == 2 && wire == 0) {
      m.forceRefresh = r.readVarint() != 0;
    } else if (field == 3 && wire == 0) {
      m.sinceGeneration = r.readVarint();
    } else if (field == 4 && wire == 0) {
      m.limit = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InventoryDomainSnapshot _decodeInventoryDomainSnapshot(Uint8List data) {
  final r = _Reader(data);
  final m = InventoryDomainSnapshot();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.domain = _inventoryDomainIdFromWire(r.readVarint());
    } else if (field == 2 && wire == 0) {
      m.status = _inventoryStatusFromWire(r.readVarint());
    } else if (field == 3 && wire == 2) {
      m.statusDetail = r.readString();
    } else if (field == 4 && wire == 0) {
      m.truncated = r.readVarint() != 0;
    } else if (field == 5 && wire == 0) {
      m.generation = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.generatedAtUnixMs = r.readVarint();
    } else if (field == 7 && wire == 0) {
      m.fullResync = r.readVarint() != 0;
    } else if (field == 8 && wire == 0) {
      m.cacheTtlMs = r.readVarint();
    } else if (field == 10 && wire == 2) {
      m.services.add(_decodeInventoryServiceEntry(r.readBytes()));
    } else if (field == 11 && wire == 2) {
      m.drivers.add(_decodeInventoryDriverEntry(r.readBytes()));
    } else if (field == 12 && wire == 2) {
      m.software.add(_decodeInventorySoftwareEntry(r.readBytes()));
    } else if (field == 13 && wire == 2) {
      m.usb.add(_decodeInventoryUsbEntry(r.readBytes()));
    } else if (field == 14 && wire == 2) {
      m.pci.add(_decodeInventoryPciEntry(r.readBytes()));
    } else if (field == 15 && wire == 2) {
      m.displays.add(_decodeInventoryPnPDeviceEntry(r.readBytes()));
    } else if (field == 16 && wire == 2) {
      m.audio.add(_decodeInventoryPnPDeviceEntry(r.readBytes()));
    } else if (field == 17 && wire == 2) {
      m.bluetooth.add(_decodeInventoryPnPDeviceEntry(r.readBytes()));
    } else if (field == 18 && wire == 2) {
      m.printers.add(_decodeInventoryPrinterEntry(r.readBytes()));
    } else if (field == 19 && wire == 2) {
      m.batteries.add(_decodeInventoryBatteryEntry(r.readBytes()));
    } else if (field == 20 && wire == 2) {
      m.motherboard.add(_decodeInventoryMotherboardEntry(r.readBytes()));
    } else if (field == 21 && wire == 2) {
      m.bios.add(_decodeInventoryBiosEntry(r.readBytes()));
    } else if (field == 22 && wire == 2) {
      m.cpu.add(_decodeInventoryCpuEntry(r.readBytes()));
    } else if (field == 23 && wire == 2) {
      m.memoryModules.add(_decodeInventoryMemoryModuleEntry(r.readBytes()));
    } else if (field == 24 && wire == 2) {
      m.storage.add(_decodeInventoryStorageEntry(r.readBytes()));
    } else if (field == 25 && wire == 2) {
      m.networkAdapters
          .add(_decodeInventoryNetworkAdapterEntry(r.readBytes()));
    } else {
      r.skip(wire);
    }
  }
  return m;
}

GetTimelineSnapshot _decodeGetTimelineSnapshot(Uint8List data) {
  final r = _Reader(data);
  final m = GetTimelineSnapshot();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.limit = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.channel = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

TimelineSnapshot _decodeTimelineSnapshot(Uint8List data) {
  final r = _Reader(data);
  final m = TimelineSnapshot();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      final sub = r.readBytes();
      m.events.add(_decodeTimelineEvent(sub));
    } else if (field == 2 && wire == 2) {
      m.channel = r.readString();
    } else if (field == 3 && wire == 0) {
      m.requestedLimit = r.readVarint();
    } else if (field == 4 && wire == 0) {
      m.collectedUnixMs = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

StartLiveMonitoring _decodeStartLiveMonitoring(Uint8List data) {
  final r = _Reader(data);
  final m = StartLiveMonitoring();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.channel = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

StopLiveMonitoring _decodeStopLiveMonitoring(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    final wire = tag & 7;
    r.skip(wire);
  }
  return StopLiveMonitoring();
}

HealthProcessEntry _decodeHealthProcessEntry(Uint8List data) {
  final r = _Reader(data);
  final m = HealthProcessEntry();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.pid = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.name = r.readString();
    } else if (field == 3 && wire == 0) {
      m.hasCpuPercent = r.readVarint() != 0;
    } else if (field == 4 && wire == 1) {
      m.cpuPercent = r.readDouble();
    } else if (field == 5 && wire == 0) {
      m.hasMemoryBytes = r.readVarint() != 0;
    } else if (field == 6 && wire == 0) {
      m.memoryBytes = r.readVarint();
    } else if (field == 7 && wire == 0) {
      m.hasGpuPercent = r.readVarint() != 0;
    } else if (field == 8 && wire == 1) {
      m.gpuPercent = r.readDouble();
    } else if (field == 9 && wire == 0) {
      m.hasDiskBps = r.readVarint() != 0;
    } else if (field == 10 && wire == 1) {
      m.diskBps = r.readDouble();
    } else if (field == 11 && wire == 0) {
      m.hasNetBps = r.readVarint() != 0;
    } else if (field == 12 && wire == 1) {
      m.netBps = r.readDouble();
    } else if (field == 13 && wire == 2) {
      m.path = r.readString();
    } else if (field == 14 && wire == 0) {
      m.threadCount = r.readVarint();
    } else if (field == 15 && wire == 0) {
      m.handleCount = r.readVarint();
    } else if (field == 16 && wire == 0) {
      m.hasCreateTime = r.readVarint() != 0;
    } else if (field == 17 && wire == 0) {
      m.createTimeUnixMs = r.readVarint();
    } else if (field == 18 && wire == 0) {
      m.hasIsCritical = r.readVarint() != 0;
    } else if (field == 19 && wire == 0) {
      m.isCritical = r.readVarint() != 0;
    } else if (field == 20 && wire == 0) {
      m.hasWorkingSetBytes = r.readVarint() != 0;
    } else if (field == 21 && wire == 0) {
      m.workingSetBytes = r.readVarint();
    } else if (field == 22 && wire == 0) {
      m.hasCommitBytes = r.readVarint() != 0;
    } else if (field == 23 && wire == 0) {
      m.commitBytes = r.readVarint();
    } else if (field == 24 && wire == 0) {
      m.hasPagedPoolBytes = r.readVarint() != 0;
    } else if (field == 25 && wire == 0) {
      m.pagedPoolBytes = r.readVarint();
    } else if (field == 26 && wire == 0) {
      m.hasNonpagedPoolBytes = r.readVarint() != 0;
    } else if (field == 27 && wire == 0) {
      m.nonpagedPoolBytes = r.readVarint();
    } else if (field == 28 && wire == 0) {
      m.hasGpuDedicatedBytes = r.readVarint() != 0;
    } else if (field == 29 && wire == 0) {
      m.gpuDedicatedBytes = r.readVarint();
    } else if (field == 30 && wire == 0) {
      m.hasGpuSharedBytes = r.readVarint() != 0;
    } else if (field == 31 && wire == 0) {
      m.gpuSharedBytes = r.readVarint();
    } else if (field == 32 && wire == 2) {
      m.gpuEngine = r.readString();
    } else if (field == 33 && wire == 0) {
      m.hasNetUploadBps = r.readVarint() != 0;
    } else if (field == 34 && wire == 1) {
      m.netUploadBps = r.readDouble();
    } else if (field == 35 && wire == 0) {
      m.hasNetDownloadBps = r.readVarint() != 0;
    } else if (field == 36 && wire == 1) {
      m.netDownloadBps = r.readDouble();
    } else if (field == 37 && wire == 0) {
      m.hasNetBytesTotal = r.readVarint() != 0;
    } else if (field == 38 && wire == 0) {
      m.netBytesTotal = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthProcessInventoryUpdate _decodeHealthProcessInventoryUpdate(
  Uint8List data,
) {
  final r = _Reader(data);
  final m = HealthProcessInventoryUpdate();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.seq = r.readVarint();
    } else if (field == 2 && wire == 0) {
      m.fullResync = r.readVarint() != 0;
    } else if (field == 3 && wire == 2) {
      m.upserts.add(_decodeHealthProcessEntry(r.readBytes()));
    } else if (field == 4 && wire == 0) {
      m.removedPids.add(r.readVarint());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

GetProcessDetails _decodeGetProcessDetails(Uint8List data) {
  final r = _Reader(data);
  final m = GetProcessDetails();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.pid = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

ProcessDetails _decodeProcessDetails(Uint8List data) {
  final r = _Reader(data);
  final m = ProcessDetails();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.pid = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.name = r.readString();
    } else if (field == 3 && wire == 2) {
      m.path = r.readString();
    } else if (field == 4 && wire == 2) {
      m.company = r.readString();
    } else if (field == 5 && wire == 2) {
      m.commandLine = r.readString();
    } else if (field == 6 && wire == 0) {
      m.hasCreateTime = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.createTimeUnixMs = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.threadCount = r.readVarint();
    } else if (field == 9 && wire == 0) {
      m.handleCount = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasPath = r.readVarint() != 0;
    } else if (field == 11 && wire == 0) {
      m.hasCompany = r.readVarint() != 0;
    } else if (field == 12 && wire == 0) {
      m.hasCommandLine = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.parentPid = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.hasParentPid = r.readVarint() != 0;
    } else if (field == 15 && wire == 2) {
      m.parentName = r.readString();
    } else if (field == 16 && wire == 0) {
      m.hasParentName = r.readVarint() != 0;
    } else if (field == 17 && wire == 2) {
      m.user = r.readString();
    } else if (field == 18 && wire == 0) {
      m.hasUser = r.readVarint() != 0;
    } else if (field == 19 && wire == 2) {
      m.integrityLevel = r.readString();
    } else if (field == 20 && wire == 0) {
      m.hasIntegrityLevel = r.readVarint() != 0;
    } else if (field == 21 && wire == 0) {
      m.elevated = r.readVarint() != 0;
    } else if (field == 22 && wire == 0) {
      m.hasElevated = r.readVarint() != 0;
    } else if (field == 23 && wire == 2) {
      m.architecture = r.readString();
    } else if (field == 24 && wire == 0) {
      m.hasArchitecture = r.readVarint() != 0;
    } else if (field == 25 && wire == 2) {
      m.productName = r.readString();
    } else if (field == 26 && wire == 0) {
      m.hasProductName = r.readVarint() != 0;
    } else if (field == 27 && wire == 0) {
      m.cpuTimeMs = r.readVarint();
    } else if (field == 28 && wire == 0) {
      m.hasCpuTime = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthVolume _decodeHealthVolume(Uint8List data) {
  final r = _Reader(data);
  final m = HealthVolume();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.mountPoint = r.readString();
    } else if (field == 3 && wire == 2) {
      m.label = r.readString();
    } else if (field == 4 && wire == 2) {
      m.fileSystem = r.readString();
    } else if (field == 5 && wire == 0) {
      m.kind = healthDriveKindFromWire(r.readVarint());
    } else if (field == 6 && wire == 0) {
      m.usedBytes = r.readVarint();
    } else if (field == 7 && wire == 0) {
      m.totalBytes = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.hasCapacity = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.includedInSummary = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthDiskHealth _decodeHealthDiskHealth(Uint8List data) {
  final r = _Reader(data);
  final m = HealthDiskHealth();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.index = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.model = r.readString();
    } else if (field == 3 && wire == 2) {
      m.bus = r.readString();
    } else if (field == 4 && wire == 0) {
      m.hasTempC = r.readVarint() != 0;
    } else if (field == 5 && wire == 1) {
      m.tempC = r.readDouble();
    } else if (field == 6 && wire == 0) {
      m.hasFailurePredicted = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.failurePredicted = r.readVarint() != 0;
    } else if (field == 8 && wire == 0) {
      m.hasCriticalWarning = r.readVarint() != 0;
    } else if (field == 9 && wire == 0) {
      m.criticalWarning = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.hasPercentageUsed = r.readVarint() != 0;
    } else if (field == 11 && wire == 0) {
      m.percentageUsed = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.hasAvailableSpare = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.availableSpare = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.availableSpareThreshold = r.readVarint();
    } else if (field == 15 && wire == 0) {
      m.hasPowerOnHours = r.readVarint() != 0;
    } else if (field == 16 && wire == 0) {
      m.powerOnHours = r.readVarint();
    } else if (field == 17 && wire == 0) {
      m.hasUnsafeShutdowns = r.readVarint() != 0;
    } else if (field == 18 && wire == 0) {
      m.unsafeShutdowns = r.readVarint();
    } else if (field == 19 && wire == 0) {
      m.hasMediaErrors = r.readVarint() != 0;
    } else if (field == 20 && wire == 0) {
      m.mediaErrors = r.readVarint();
    } else if (field == 21 && wire == 0) {
      m.hasBytesRead = r.readVarint() != 0;
    } else if (field == 22 && wire == 0) {
      m.bytesRead = r.readVarint();
    } else if (field == 23 && wire == 0) {
      m.hasBytesWritten = r.readVarint() != 0;
    } else if (field == 24 && wire == 0) {
      m.bytesWritten = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}
HealthGpuAdapter _decodeHealthGpuAdapter(Uint8List data) {
  final r = _Reader(data);
  final m = HealthGpuAdapter();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.luidHigh = r.readVarint().toSigned(32);
    } else if (field == 2 && wire == 0) {
      m.luidLow = r.readVarint();
    } else if (field == 3 && wire == 2) {
      m.name = r.readString();
    } else if (field == 4 && wire == 2) {
      m.vendor = r.readString();
    } else if (field == 5 && wire == 0) {
      m.isPrimary = r.readVarint() != 0;
    } else if (field == 6 && wire == 0) {
      m.dedicatedTotalBytes = r.readVarint();
    } else if (field == 7 && wire == 0) {
      m.sharedTotalBytes = r.readVarint();
    } else if (field == 8 && wire == 0) {
      m.hasPercent = r.readVarint() != 0;
    } else if (field == 9 && wire == 1) {
      m.percent = r.readDouble();
    } else if (field == 10 && wire == 0) {
      m.hasDedicatedUsed = r.readVarint() != 0;
    } else if (field == 11 && wire == 0) {
      m.dedicatedUsedBytes = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.hasSharedUsed = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.sharedUsedBytes = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthPhysicalDisk _decodeHealthPhysicalDisk(Uint8List data) {
  final r = _Reader(data);
  final m = HealthPhysicalDisk();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.id = r.readString();
    } else if (field == 2 && wire == 2) {
      m.name = r.readString();
    } else if (field == 3 && wire == 0) {
      m.hasReadBps = r.readVarint() != 0;
    } else if (field == 4 && wire == 1) {
      m.readBps = r.readDouble();
    } else if (field == 5 && wire == 0) {
      m.hasWriteBps = r.readVarint() != 0;
    } else if (field == 6 && wire == 1) {
      m.writeBps = r.readDouble();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthStaticInfo _decodeHealthStaticInfo(Uint8List data) {
  final r = _Reader(data);
  final m = HealthStaticInfo();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.windowsEdition = r.readString();
    } else if (field == 2 && wire == 2) {
      m.windowsVersion = r.readString();
    } else if (field == 3 && wire == 2) {
      m.cpuModel = r.readString();
    } else if (field == 4 && wire == 2) {
      m.gpuModel = r.readString();
    } else if (field == 5 && wire == 0) {
      m.installedRamBytes = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.primaryStorageBytes = r.readVarint();
    } else if (field == 7 && wire == 2) {
      m.activeNetworkAdapter = r.readString();
    } else if (field == 8 && wire == 0) {
      m.cpuBaseMhz = r.readVarint();
    } else if (field == 9 && wire == 0) {
      m.cpuSockets = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.cpuCores = r.readVarint();
    } else if (field == 11 && wire == 0) {
      m.cpuLogicalProcessors = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.cpuVirtualizationEnabled = r.readVarint() != 0;
    } else if (field == 13 && wire == 0) {
      m.gpuDedicatedBytes = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.gpuSharedBytes = r.readVarint();
    } else if (field == 15 && wire == 2) {
      m.cpuArchitecture = r.readString();
    } else if (field == 16 && wire == 2) {
      m.cpuInstructionSet = r.readString();
    } else if (field == 17 && wire == 0) {
      m.cpuNumaNodes = r.readVarint();
    } else if (field == 18 && wire == 0) {
      m.hasCpuSmt = r.readVarint() != 0;
    } else if (field == 19 && wire == 0) {
      m.cpuSmtEnabled = r.readVarint() != 0;
    } else if (field == 20 && wire == 0) {
      m.hasCpuL1Cache = r.readVarint() != 0;
    } else if (field == 21 && wire == 0) {
      m.cpuL1CacheBytes = r.readVarint();
    } else if (field == 22 && wire == 0) {
      m.hasCpuL2Cache = r.readVarint() != 0;
    } else if (field == 23 && wire == 0) {
      m.cpuL2CacheBytes = r.readVarint();
    } else if (field == 24 && wire == 0) {
      m.hasCpuL3Cache = r.readVarint() != 0;
    } else if (field == 25 && wire == 0) {
      m.cpuL3CacheBytes = r.readVarint();
    } else if (field == 26 && wire == 2) {
      m.cpuVirtualizationVendor = r.readString();
    } else if (field == 27 && wire == 2) {
      m.gpuVendor = r.readString();
    } else if (field == 28 && wire == 2) {
      m.gpuDriverVersion = r.readString();
    } else if (field == 29 && wire == 2) {
      m.gpuDriverDate = r.readString();
    } else if (field == 30 && wire == 0) {
      m.hasGpuLuid = r.readVarint() != 0;
    } else if (field == 31 && wire == 0) {
      m.gpuLuidHigh = r.readVarint();
    } else if (field == 32 && wire == 0) {
      m.gpuLuidLow = r.readVarint();
    } else if (field == 33 && wire == 2) {
      m.gpuDirectxVersion = r.readString();
    } else if (field == 34 && wire == 2) {
      m.gpuWddmVersion = r.readString();
    } else if (field == 35 && wire == 0) {
      m.hasGpuHardwareScheduling = r.readVarint() != 0;
    } else if (field == 36 && wire == 0) {
      m.gpuHardwareScheduling = r.readVarint() != 0;
    } else if (field == 37 && wire == 2) {
      m.gpuPcieLinkSpeed = r.readString();
    } else if (field == 38 && wire == 2) {
      m.gpuPcieLinkWidth = r.readString();
    } else if (field == 39 && wire == 2) {
      m.netManufacturer = r.readString();
    } else if (field == 40 && wire == 2) {
      m.netDescription = r.readString();
    } else if (field == 41 && wire == 2) {
      m.netMacAddress = r.readString();
    } else if (field == 42 && wire == 2) {
      m.netDriverVersion = r.readString();
    } else if (field == 43 && wire == 2) {
      m.netDriverDate = r.readString();
    } else if (field == 44 && wire == 2) {
      m.netConnectionType = r.readString();
    } else if (field == 45 && wire == 2) {
      m.netDuplex = r.readString();
    } else if (field == 46 && wire == 0) {
      m.hasNetMtu = r.readVarint() != 0;
    } else if (field == 47 && wire == 0) {
      m.netMtu = r.readVarint();
    } else if (field == 48 && wire == 0) {
      m.hasNetIfIndex = r.readVarint() != 0;
    } else if (field == 49 && wire == 0) {
      m.netIfIndex = r.readVarint();
    } else if (field == 50 && wire == 0) {
      m.hasNetLinkSpeedBps = r.readVarint() != 0;
    } else if (field == 51 && wire == 0) {
      m.netLinkSpeedBps = r.readVarint();
    } else if (field == 52 && wire == 0) {
      m.hasNetDhcp = r.readVarint() != 0;
    } else if (field == 53 && wire == 0) {
      m.netDhcpEnabled = r.readVarint() != 0;
    } else if (field == 54 && wire == 2) {
      m.netDhcpServer = r.readString();
    } else if (field == 55 && wire == 0) {
      m.hasNetLeaseObtained = r.readVarint() != 0;
    } else if (field == 56 && wire == 0) {
      m.netLeaseObtainedUnixMs = r.readVarint();
    } else if (field == 57 && wire == 0) {
      m.hasNetLeaseExpires = r.readVarint() != 0;
    } else if (field == 58 && wire == 0) {
      m.netLeaseExpiresUnixMs = r.readVarint();
    } else if (field == 59 && wire == 0) {
      m.hasMemSlotsUsed = r.readVarint() != 0;
    } else if (field == 60 && wire == 0) {
      m.memSlotsUsed = r.readVarint();
    } else if (field == 61 && wire == 0) {
      m.hasMemModuleCount = r.readVarint() != 0;
    } else if (field == 62 && wire == 0) {
      m.memModuleCount = r.readVarint();
    } else if (field == 63 && wire == 2) {
      m.memDdrGeneration = r.readString();
    } else if (field == 64 && wire == 0) {
      m.hasMemSpeedMhz = r.readVarint() != 0;
    } else if (field == 65 && wire == 0) {
      m.memSpeedMhz = r.readVarint();
    } else if (field == 66 && wire == 2) {
      m.memFormFactor = r.readString();
    } else if (field == 67 && wire == 0) {
      m.hasMemEcc = r.readVarint() != 0;
    } else if (field == 68 && wire == 0) {
      m.memEcc = r.readVarint() != 0;
    } else if (field == 69 && wire == 0) {
      m.hasMemChannels = r.readVarint() != 0;
    } else if (field == 70 && wire == 0) {
      m.memChannels = r.readVarint();
    } else if (field == 71 && wire == 2) {
      m.memDimmVendor = r.readString();
    } else if (field == 72 && wire == 2) {
      m.memDimmPartNumber = r.readString();
    } else if (field == 73 && wire == 2) {
      m.memDimmSerial = r.readString();
    } else if (field == 74 && wire == 2) {
      m.diskInterface = r.readString();
    } else if (field == 75 && wire == 2) {
      m.diskBus = r.readString();
    } else if (field == 76 && wire == 2) {
      m.diskModel = r.readString();
    } else if (field == 77 && wire == 2) {
      m.diskSerial = r.readString();
    } else if (field == 78 && wire == 2) {
      m.diskFirmware = r.readString();
    } else if (field == 79 && wire == 2) {
      m.diskPartitionStyle = r.readString();
    } else if (field == 80 && wire == 0) {
      m.hasDiskSectorSize = r.readVarint() != 0;
    } else if (field == 81 && wire == 0) {
      m.diskSectorSize = r.readVarint();
    } else if (field == 82 && wire == 0) {
      m.hasDiskRotationRate = r.readVarint() != 0;
    } else if (field == 83 && wire == 0) {
      m.diskRotationRate = r.readVarint();
    } else if (field == 84 && wire == 0) {
      m.hasDiskTrim = r.readVarint() != 0;
    } else if (field == 85 && wire == 0) {
      m.diskTrimSupported = r.readVarint() != 0;
    } else if (field == 86 && wire == 2) {
      m.gpuPciLocation = r.readString();
    } else if (field == 87 && wire == 0) {
      m.hasGpuResizableBar = r.readVarint() != 0;
    } else if (field == 88 && wire == 0) {
      m.gpuResizableBar = r.readVarint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthSample _decodeHealthSample(Uint8List data) {
  final r = _Reader(data);
  final m = HealthSample();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.unixMs = r.readVarint();
    } else if (field == 2 && wire == 0) {
      m.hasCpuPercent = r.readVarint() != 0;
    } else if (field == 3 && wire == 1) {
      m.cpuPercent = r.readDouble();
    } else if (field == 4 && wire == 0) {
      m.memoryUsedBytes = r.readVarint();
    } else if (field == 5 && wire == 0) {
      m.memoryTotalBytes = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.hasGpuPercent = r.readVarint() != 0;
    } else if (field == 7 && wire == 1) {
      m.gpuPercent = r.readDouble();
    } else if (field == 8 && wire == 0) {
      m.hasNetDownloadBps = r.readVarint() != 0;
    } else if (field == 9 && wire == 1) {
      m.netDownloadBps = r.readDouble();
    } else if (field == 10 && wire == 0) {
      m.hasNetUploadBps = r.readVarint() != 0;
    } else if (field == 11 && wire == 1) {
      m.netUploadBps = r.readDouble();
    } else if (field == 12 && wire == 0) {
      m.hasDiskReadBps = r.readVarint() != 0;
    } else if (field == 13 && wire == 1) {
      m.diskReadBps = r.readDouble();
    } else if (field == 14 && wire == 0) {
      m.hasDiskWriteBps = r.readVarint() != 0;
    } else if (field == 15 && wire == 1) {
      m.diskWriteBps = r.readDouble();
    } else if (field == 16 && wire == 0) {
      m.diskUsedBytes = r.readVarint();
    } else if (field == 17 && wire == 0) {
      m.diskTotalBytes = r.readVarint();
    } else if (field == 18 && wire == 0) {
      m.uptimeMs = r.readVarint();
    } else if (field == 19 && wire == 0) {
      m.hasCpuTempC = r.readVarint() != 0;
    } else if (field == 20 && wire == 1) {
      m.cpuTempC = r.readDouble();
    } else if (field == 21 && wire == 0) {
      m.hasGpuTempC = r.readVarint() != 0;
    } else if (field == 22 && wire == 1) {
      m.gpuTempC = r.readDouble();
    } else if (field == 23 && wire == 0) {
      m.hasSsdTempC = r.readVarint() != 0;
    } else if (field == 24 && wire == 1) {
      m.ssdTempC = r.readDouble();
    } else if (field == 25 && wire == 0) {
      m.hasCpuCurrentMhz = r.readVarint() != 0;
    } else if (field == 26 && wire == 1) {
      m.cpuCurrentMhz = r.readDouble();
    } else if (field == 27 && wire == 0) {
      m.memoryAvailableBytes = r.readVarint();
    } else if (field == 28 && wire == 0) {
      m.hasMemoryCommitted = r.readVarint() != 0;
    } else if (field == 29 && wire == 0) {
      m.memoryCommittedBytes = r.readVarint();
    } else if (field == 30 && wire == 0) {
      m.memoryCommitLimitBytes = r.readVarint();
    } else if (field == 31 && wire == 0) {
      m.hasMemoryCached = r.readVarint() != 0;
    } else if (field == 32 && wire == 0) {
      m.memoryCachedBytes = r.readVarint();
    } else if (field == 33 && wire == 2) {
      m.ipv4 = r.readString();
    } else if (field == 34 && wire == 2) {
      m.ipv6 = r.readString();
    } else if (field == 35 && wire == 2) {
      m.gateway = r.readString();
    } else if (field == 36 && wire == 2) {
      m.dns = r.readString();
    } else if (field == 37 && wire == 2) {
      m.topCpu.add(_decodeHealthProcessEntry(r.readBytes()));
    } else if (field == 38 && wire == 2) {
      m.topMemory.add(_decodeHealthProcessEntry(r.readBytes()));
    } else if (field == 39 && wire == 2) {
      m.topGpu.add(_decodeHealthProcessEntry(r.readBytes()));
    } else if (field == 40 && wire == 2) {
      m.topDisk.add(_decodeHealthProcessEntry(r.readBytes()));
    } else if (field == 41 && wire == 2) {
      m.topNetwork.add(_decodeHealthProcessEntry(r.readBytes()));
    } else if (field == 42 && wire == 1) {
      m.cpuCorePercent.add(r.readDouble());
    } else if (field == 43 && wire == 2) {
      m.volumes.add(_decodeHealthVolume(r.readBytes()));
    } else if (field == 44 && wire == 2) {
      m.disks.add(_decodeHealthPhysicalDisk(r.readBytes()));
    } else if (field == 45 && wire == 0) {
      m.hasMemoryCompressed = r.readVarint() != 0;
    } else if (field == 46 && wire == 0) {
      m.memoryCompressedBytes = r.readVarint();
    } else if (field == 47 && wire == 0) {
      m.hasMemoryHardwareReserved = r.readVarint() != 0;
    } else if (field == 48 && wire == 0) {
      m.memoryHardwareReservedBytes = r.readVarint();
    } else if (field == 49 && wire == 0) {
      m.hasMemoryPagedPool = r.readVarint() != 0;
    } else if (field == 50 && wire == 0) {
      m.memoryPagedPoolBytes = r.readVarint();
    } else if (field == 51 && wire == 0) {
      m.hasMemoryNonpagedPool = r.readVarint() != 0;
    } else if (field == 52 && wire == 0) {
      m.memoryNonpagedPoolBytes = r.readVarint();
    } else if (field == 53 && wire == 0) {
      m.hasMemoryPageFaultsPerSec = r.readVarint() != 0;
    } else if (field == 54 && wire == 1) {
      m.memoryPageFaultsPerSec = r.readDouble();
    } else if (field == 55 && wire == 0) {
      m.hasGpuUtil3d = r.readVarint() != 0;
    } else if (field == 56 && wire == 1) {
      m.gpuUtil3d = r.readDouble();
    } else if (field == 57 && wire == 0) {
      m.hasGpuUtilCompute = r.readVarint() != 0;
    } else if (field == 58 && wire == 1) {
      m.gpuUtilCompute = r.readDouble();
    } else if (field == 59 && wire == 0) {
      m.hasGpuUtilCopy = r.readVarint() != 0;
    } else if (field == 60 && wire == 1) {
      m.gpuUtilCopy = r.readDouble();
    } else if (field == 61 && wire == 0) {
      m.hasGpuUtilVideoDecode = r.readVarint() != 0;
    } else if (field == 62 && wire == 1) {
      m.gpuUtilVideoDecode = r.readDouble();
    } else if (field == 63 && wire == 0) {
      m.hasGpuUtilVideoEncode = r.readVarint() != 0;
    } else if (field == 64 && wire == 1) {
      m.gpuUtilVideoEncode = r.readDouble();
    } else if (field == 65 && wire == 0) {
      m.hasGpuDedicatedUsed = r.readVarint() != 0;
    } else if (field == 66 && wire == 0) {
      m.gpuDedicatedUsedBytes = r.readVarint();
    } else if (field == 67 && wire == 0) {
      m.hasGpuSharedUsed = r.readVarint() != 0;
    } else if (field == 68 && wire == 0) {
      m.gpuSharedUsedBytes = r.readVarint();
    } else if (field == 69 && wire == 0) {
      m.hasGpuClockMhz = r.readVarint() != 0;
    } else if (field == 70 && wire == 1) {
      m.gpuClockMhz = r.readDouble();
    } else if (field == 71 && wire == 0) {
      m.hasGpuMemoryClockMhz = r.readVarint() != 0;
    } else if (field == 72 && wire == 1) {
      m.gpuMemoryClockMhz = r.readDouble();
    } else if (field == 73 && wire == 0) {
      m.hasGpuFanRpm = r.readVarint() != 0;
    } else if (field == 74 && wire == 1) {
      m.gpuFanRpm = r.readDouble();
    } else if (field == 75 && wire == 0) {
      m.hasGpuPowerPercent = r.readVarint() != 0;
    } else if (field == 76 && wire == 1) {
      m.gpuPowerPercent = r.readDouble();
    } else if (field == 77 && wire == 0) {
      m.hasNetPeakDownloadBps = r.readVarint() != 0;
    } else if (field == 78 && wire == 1) {
      m.netPeakDownloadBps = r.readDouble();
    } else if (field == 79 && wire == 0) {
      m.hasNetPeakUploadBps = r.readVarint() != 0;
    } else if (field == 80 && wire == 1) {
      m.netPeakUploadBps = r.readDouble();
    } else if (field == 81 && wire == 0) {
      m.hasNetAvgDownloadBps = r.readVarint() != 0;
    } else if (field == 82 && wire == 1) {
      m.netAvgDownloadBps = r.readDouble();
    } else if (field == 83 && wire == 0) {
      m.hasNetAvgUploadBps = r.readVarint() != 0;
    } else if (field == 84 && wire == 1) {
      m.netAvgUploadBps = r.readDouble();
    } else if (field == 85 && wire == 0) {
      m.hasNetUtilizationPercent = r.readVarint() != 0;
    } else if (field == 86 && wire == 1) {
      m.netUtilizationPercent = r.readDouble();
    } else if (field == 87 && wire == 0) {
      m.hasNetConnectionMs = r.readVarint() != 0;
    } else if (field == 88 && wire == 0) {
      m.netConnectionMs = r.readVarint();
    } else if (field == 89 && wire == 0) {
      m.hasNetBytesSent = r.readVarint() != 0;
    } else if (field == 90 && wire == 0) {
      m.netBytesSent = r.readVarint();
    } else if (field == 91 && wire == 0) {
      m.hasNetBytesReceived = r.readVarint() != 0;
    } else if (field == 92 && wire == 0) {
      m.netBytesReceived = r.readVarint();
    } else if (field == 93 && wire == 0) {
      m.hasNetPacketsSent = r.readVarint() != 0;
    } else if (field == 94 && wire == 0) {
      m.netPacketsSent = r.readVarint();
    } else if (field == 95 && wire == 0) {
      m.hasNetPacketsReceived = r.readVarint() != 0;
    } else if (field == 96 && wire == 0) {
      m.netPacketsReceived = r.readVarint();
    } else if (field == 97 && wire == 0) {
      m.hasNetErrors = r.readVarint() != 0;
    } else if (field == 98 && wire == 0) {
      m.netErrors = r.readVarint();
    } else if (field == 99 && wire == 0) {
      m.hasNetDrops = r.readVarint() != 0;
    } else if (field == 100 && wire == 0) {
      m.netDrops = r.readVarint();
    } else if (field == 101 && wire == 2) {
      m.netSsid = r.readString();
    } else if (field == 102 && wire == 0) {
      m.hasNetSignalPercent = r.readVarint() != 0;
    } else if (field == 103 && wire == 1) {
      m.netSignalPercent = r.readDouble();
    } else if (field == 104 && wire == 2) {
      m.netWifiChannel = r.readString();
    } else if (field == 105 && wire == 2) {
      m.netWifiFrequency = r.readString();
    } else if (field == 106 && wire == 2) {
      m.netWifiSecurity = r.readString();
    } else if (field == 107 && wire == 0) {
      m.hasGpuUtilVideoProcessing = r.readVarint() != 0;
    } else if (field == 108 && wire == 1) {
      m.gpuUtilVideoProcessing = r.readDouble();
    } else if (field == 109 && wire == 0) {
      m.hasDiskPowerOnHours = r.readVarint() != 0;
    } else if (field == 110 && wire == 0) {
      m.diskPowerOnHours = r.readVarint();
    } else if (field == 111 && wire == 0) {
      m.hasDiskTotalBytesWritten = r.readVarint() != 0;
    } else if (field == 112 && wire == 0) {
      m.diskTotalBytesWritten = r.readVarint();
    } else if (field == 113 && wire == 0) {
      m.hasDiskTotalBytesRead = r.readVarint() != 0;
    } else if (field == 114 && wire == 0) {
      m.diskTotalBytesRead = r.readVarint();
    } else if (field == 115 && wire == 0) {
      m.hasDiskSmartOk = r.readVarint() != 0;
    } else if (field == 116 && wire == 0) {
      m.diskSmartOk = r.readVarint() != 0;
    } else if (field == 117 && wire == 2) {
      m.diskHealth.add(_decodeHealthDiskHealth(r.readBytes()));
    } else if (field == 118 && wire == 2) {
      m.gpus.add(_decodeHealthGpuAdapter(r.readBytes()));
    } else {
      r.skip(wire);
    }
  }
  return m;
}

GetHealthSnapshot _decodeGetHealthSnapshot(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    final wire = tag & 7;
    r.skip(wire);
  }
  return GetHealthSnapshot();
}

HealthSnapshot _decodeHealthSnapshot(Uint8List data) {
  final r = _Reader(data);
  final m = HealthSnapshot();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.info = _decodeHealthStaticInfo(r.readBytes());
    } else if (field == 2 && wire == 2) {
      m.sample = _decodeHealthSample(r.readBytes());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

HealthUpdate _decodeHealthUpdate(Uint8List data) {
  final r = _Reader(data);
  final m = HealthUpdate();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.sample = _decodeHealthSample(r.readBytes());
    } else if (field == 2 && wire == 2) {
      m.processInventory = _decodeHealthProcessInventoryUpdate(r.readBytes());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

StartHealthMonitoring _decodeStartHealthMonitoring(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    final wire = tag & 7;
    r.skip(wire);
  }
  return StartHealthMonitoring();
}

StopHealthMonitoring _decodeStopHealthMonitoring(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    final wire = tag & 7;
    r.skip(wire);
  }
  return StopHealthMonitoring();
}

GetDiagnosticsSnapshot _decodeGetDiagnosticsSnapshot(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    final wire = tag & 7;
    r.skip(wire);
  }
  return GetDiagnosticsSnapshot();
}

DiagnosticsSnapshot _decodeDiagnosticsSnapshot(Uint8List data) {
  final r = _Reader(data);
  final m = DiagnosticsSnapshot();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.serviceVersion = r.readString();
    } else if (field == 2 && wire == 0) {
      m.protocolVersion = r.readVarint();
    } else if (field == 3 && wire == 0) {
      m.serviceStartUnixMs = r.readVarint();
    } else if (field == 4 && wire == 0) {
      m.serviceUptimeMs = r.readVarint();
    } else if (field == 5 && wire == 2) {
      m.runMode = r.readString();
    } else if (field == 6 && wire == 0) {
      m.ipcListening = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.liveSubscribed = r.readVarint() != 0;
    } else if (field == 8 && wire == 2) {
      m.liveChannel = r.readString();
    } else if (field == 9 && wire == 0) {
      m.liveEventsPushed = r.readVarint();
    } else if (field == 10 && wire == 0) {
      m.liveEventsDropped = r.readVarint();
    } else if (field == 11 && wire == 0) {
      m.liveSubscriberReconnects = r.readVarint();
    } else if (field == 12 && wire == 0) {
      m.lastLiveEventUnixMs = r.readVarint();
    } else if (field == 13 && wire == 2) {
      m.lastLiveEventTitle = r.readString();
    } else if (field == 14 && wire == 0) {
      m.liveQueueDepth = r.readVarint();
    } else if (field == 15 && wire == 0) {
      m.liveQueueCapacity = r.readVarint();
    } else if (field == 16 && wire == 0) {
      m.ipcMessagesReceived = r.readVarint();
    } else if (field == 17 && wire == 0) {
      m.ipcMessagesSent = r.readVarint();
    } else if (field == 18 && wire == 0) {
      m.ipcErrors = r.readVarint();
    } else if (field == 19 && wire == 0) {
      m.connectedClients = r.readVarint();
    } else if (field == 20 && wire == 0) {
      m.servicePid = r.readVarint();
    } else if (field == 21 && wire == 0) {
      m.hasCpuPercent = r.readVarint() != 0;
    } else if (field == 22 && wire == 1) {
      m.cpuPercent = r.readDouble();
    } else if (field == 23 && wire == 0) {
      m.workingSetBytes = r.readVarint();
    } else if (field == 24 && wire == 0) {
      m.threadCount = r.readVarint();
    } else if (field == 25 && wire == 0) {
      m.handleCount = r.readVarint();
    } else if (field == 26 && wire == 0) {
      m.stageEventLog = r.readVarint();
    } else if (field == 27 && wire == 0) {
      m.stageCollector = r.readVarint();
    } else if (field == 28 && wire == 0) {
      m.stageIntelligence = r.readVarint();
    } else if (field == 29 && wire == 0) {
      m.stageIpc = r.readVarint();
    } else if (field == 30 && wire == 2) {
      m.stageDetail = r.readString();
    } else if (field == 31 && wire == 2) {
      m.windowsEdition = r.readString();
    } else if (field == 32 && wire == 2) {
      m.windowsVersion = r.readString();
    } else if (field == 33 && wire == 2) {
      m.executablePath = r.readString();
    } else if (field == 34 && wire == 2) {
      m.buildVersion = r.readString();
    } else if (field == 35 && wire == 2) {
      m.gitCommit = r.readString();
    } else if (field == 36 && wire == 2) {
      m.binarySha256 = r.readString();
    } else if (field == 37 && wire == 2) {
      m.installPath = r.readString();
    } else if (field == 38 && wire == 0) {
      m.hasPathsMatch = r.readVarint() != 0;
    } else if (field == 39 && wire == 0) {
      m.pathsMatch = r.readVarint() != 0;
    } else if (field == 40 && wire == 2) {
      m.scmState = r.readString();
    } else if (field == 41 && wire == 2) {
      m.scmStartupType = r.readString();
    } else if (field == 42 && wire == 0) {
      m.ipcBytesReceived = r.readVarint();
    } else if (field == 43 && wire == 0) {
      m.ipcBytesSent = r.readVarint();
    } else if (field == 44 && wire == 0) {
      m.hasIpcMessagesPerSec = r.readVarint() != 0;
    } else if (field == 45 && wire == 1) {
      m.ipcMessagesPerSec = r.readDouble();
    } else if (field == 46 && wire == 0) {
      m.hasIpcBytesPerSec = r.readVarint() != 0;
    } else if (field == 47 && wire == 1) {
      m.ipcBytesPerSec = r.readDouble();
    } else if (field == 48 && wire == 0) {
      m.healthMonitoringActive = r.readVarint() != 0;
    } else if (field == 49 && wire == 1) {
      m.healthSampleRateHz = r.readDouble();
    } else if (field == 50 && wire == 0) {
      m.networkEtwRunning = r.readVarint() != 0;
    } else if (field == 51 && wire == 2) {
      m.networkEtwLastError = r.readString();
    } else if (field == 52 && wire == 2) {
      m.stageEventLogDetail = r.readString();
    } else if (field == 53 && wire == 2) {
      m.stageCollectorDetail = r.readString();
    } else if (field == 54 && wire == 2) {
      m.stageIntelligenceDetail = r.readString();
    } else if (field == 55 && wire == 2) {
      m.stageIpcDetail = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

InjectDiagnosticsTestEvent _decodeInjectDiagnosticsTestEvent(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    final wire = tag & 7;
    r.skip(wire);
  }
  return InjectDiagnosticsTestEvent();
}

CrashKind _crashKindFromWire(int v) {
  if (v < 0 || v >= CrashKind.values.length) {
    return CrashKind.unspecified;
  }
  return CrashKind.values[v];
}

FaultingModuleOrigin _faultingModuleOriginFromWire(int v) {
  if (v < 0 || v >= FaultingModuleOrigin.values.length) {
    return FaultingModuleOrigin.unknown;
  }
  return FaultingModuleOrigin.values[v];
}

CrashOccurrence _decodeCrashOccurrence(Uint8List data) {
  final r = _Reader(data);
  final m = CrashOccurrence();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.timestampUnixMs = r.readVarint();
    } else if (field == 2 && wire == 2) {
      m.channel = r.readString();
    } else if (field == 3 && wire == 0) {
      m.recordId = r.readVarint();
    } else if (field == 4 && wire == 2) {
      m.version = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

CrashVersion _decodeCrashVersion(Uint8List data) {
  final r = _Reader(data);
  final m = CrashVersion();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.version = r.readString();
    } else if (field == 2 && wire == 0) {
      m.count = r.readVarint();
    } else if (field == 3 && wire == 0) {
      m.lastUnixMs = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

CrashGroup _decodeCrashGroup(Uint8List data) {
  final r = _Reader(data);
  final m = CrashGroup();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.kind = _crashKindFromWire(r.readVarint());
    } else if (field == 2 && wire == 2) {
      m.key = r.readString();
    } else if (field == 3 && wire == 2) {
      m.subject = r.readString();
    } else if (field == 4 && wire == 2) {
      m.moduleName = r.readString();
    } else if (field == 5 && wire == 2) {
      m.modulePath = r.readString();
    } else if (field == 6 && wire == 2) {
      m.moduleCompany = r.readString();
    } else if (field == 7 && wire == 0) {
      m.moduleOrigin = _faultingModuleOriginFromWire(r.readVarint());
    } else if (field == 8 && wire == 0) {
      m.code = r.readVarint();
    } else if (field == 9 && wire == 0) {
      m.hasCode = r.readVarint() != 0;
    } else if (field == 10 && wire == 2) {
      m.title = r.readString();
    } else if (field == 11 && wire == 2) {
      m.summary = r.readString();
    } else if (field == 12 && wire == 2) {
      m.recommendation = r.readString();
    } else if (field == 13 && wire == 0) {
      m.count = r.readVarint();
    } else if (field == 14 && wire == 0) {
      m.firstUnixMs = r.readVarint();
    } else if (field == 15 && wire == 0) {
      m.lastUnixMs = r.readVarint();
    } else if (field == 16 && wire == 0) {
      m.occurrenceUnixMs.add(r.readVarint());
    } else if (field == 17 && wire == 2) {
      m.versions.add(_decodeCrashVersion(r.readBytes()));
    } else if (field == 18 && wire == 2) {
      m.recent.add(_decodeCrashOccurrence(r.readBytes()));
    } else {
      r.skip(wire);
    }
  }
  return m;
}

GetCrashHistory _decodeGetCrashHistory(Uint8List data) {
  final r = _Reader(data);
  final m = GetCrashHistory();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.days = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

CrashHistory _decodeCrashHistory(Uint8List data) {
  final r = _Reader(data);
  final m = CrashHistory();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      m.days = r.readVarint();
    } else if (field == 2 && wire == 0) {
      m.collectedUnixMs = r.readVarint();
    } else if (field == 3 && wire == 2) {
      m.groups.add(_decodeCrashGroup(r.readBytes()));
    } else if (field == 4 && wire == 0) {
      m.scannedEvents = r.readVarint();
    } else if (field == 5 && wire == 0) {
      m.truncated = r.readVarint() != 0;
    } else if (field == 6 && wire == 2) {
      m.unreadableChannels.add(r.readString());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

T _enumFromWire<T>(List<T> values, int v) =>
    v < 0 || v >= values.length ? values.first : values[v];

EventLogChannelInfo _decodeEventLogChannelInfo(Uint8List data) {
  final r = _Reader(data);
  final m = EventLogChannelInfo();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.path = r.readString();
    } else if (field == 2 && wire == 0) {
      m.type = _enumFromWire(EventLogChannelType.values, r.readVarint());
    } else if (field == 3 && wire == 0) {
      m.enabled = r.readVarint() != 0;
    } else if (field == 4 && wire == 0) {
      m.access = _enumFromWire(EventLogChannelAccess.values, r.readVarint());
    } else if (field == 5 && wire == 0) {
      m.recordCount = r.readVarint();
    } else if (field == 6 && wire == 0) {
      m.hasRecordCount = r.readVarint() != 0;
    } else if (field == 7 && wire == 0) {
      m.builtIn = r.readVarint() != 0;
    } else if (field == 8 && wire == 0) {
      m.tracked = r.readVarint() != 0;
    } else if (field == 9 && wire == 2) {
      m.detail = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

ListEventLogChannels _decodeListEventLogChannels(Uint8List data) {
  final r = _Reader(data);
  while (r.hasMore) {
    final tag = r.readVarint();
    r.skip(tag & 7);
  }
  return ListEventLogChannels();
}

EventLogChannelList _decodeEventLogChannelList(Uint8List data) {
  final r = _Reader(data);
  final m = EventLogChannelList();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.channels.add(_decodeEventLogChannelInfo(r.readBytes()));
    } else if (field == 2 && wire == 0) {
      m.collectedUnixMs = r.readVarint();
    } else if (field == 3 && wire == 0) {
      m.maxTracked = r.readVarint();
    } else if (field == 4 && wire == 0) {
      m.skippedChannels = r.readVarint();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

SetTrackedChannels _decodeSetTrackedChannels(Uint8List data) {
  final r = _Reader(data);
  final m = SetTrackedChannels();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.channels.add(r.readString());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

TrackedChannelResult _decodeTrackedChannelResult(Uint8List data) {
  final r = _Reader(data);
  final m = TrackedChannelResult();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.path = r.readString();
    } else if (field == 2 && wire == 0) {
      m.status = _enumFromWire(TrackedChannelStatus.values, r.readVarint());
    } else if (field == 3 && wire == 2) {
      m.detail = r.readString();
    } else {
      r.skip(wire);
    }
  }
  return m;
}

TrackedChannels _decodeTrackedChannels(Uint8List data) {
  final r = _Reader(data);
  final m = TrackedChannels();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 2) {
      m.results.add(_decodeTrackedChannelResult(r.readBytes()));
    } else if (field == 2 && wire == 0) {
      m.maxTracked = r.readVarint();
    } else if (field == 3 && wire == 2) {
      m.tracked.add(r.readString());
    } else {
      r.skip(wire);
    }
  }
  return m;
}

Envelope decodeEnvelope(Uint8List data) {
  final r = _Reader(data);
  final env = Envelope();
  while (r.hasMore) {
    final tag = r.readVarint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (field == 1 && wire == 0) {
      env.requestId = r.readVarint();
    } else if (wire == 2 &&
        (field == 10 ||
            field == 11 ||
            field == 12 ||
            field == 13 ||
            field == 14 ||
            field == 20 ||
            field == 21 ||
            field == 22 ||
            field == 23 ||
            field == 24 ||
            field == 25 ||
            field == 26 ||
            field == 27 ||
            field == 28 ||
            field == 29 ||
            field == 30 ||
            field == 31 ||
            field == 32 ||
            field == 33 ||
            field == 34 ||
            field == 35 ||
            field == 36 ||
            field == 37 ||
            field == 38 ||
            field == 39 ||
            field == 40 ||
            field == 41 ||
            field == 42 ||
            field == 43 ||
            field == 44 ||
            field == 99)) {
      final len = r.readVarint();
      final sub = r.data.sublist(r.offset, r.offset + len);
      r.offset += len;
      switch (field) {
        case 10:
          env.body = _decodeClientHello(sub);
          break;
        case 11:
          env.body = _decodeServerHello(sub);
          break;
        case 12:
          env.body = _decodePing(sub);
          break;
        case 13:
          env.body = _decodePong(sub);
          break;
        case 14:
          env.body = _decodeHeartbeat(sub);
          break;
        case 20:
          env.body = _decodeGetTimelineSnapshot(sub);
          break;
        case 21:
          env.body = _decodeTimelineSnapshot(sub);
          break;
        case 22:
          env.body = _decodeTimelineEvent(sub);
          break;
        case 23:
          env.body = _decodeStartLiveMonitoring(sub);
          break;
        case 24:
          env.body = _decodeStopLiveMonitoring(sub);
          break;
        case 25:
          env.body = _decodeGetHealthSnapshot(sub);
          break;
        case 26:
          env.body = _decodeHealthSnapshot(sub);
          break;
        case 27:
          env.body = _decodeHealthUpdate(sub);
          break;
        case 28:
          env.body = _decodeStartHealthMonitoring(sub);
          break;
        case 29:
          env.body = _decodeStopHealthMonitoring(sub);
          break;
        case 30:
          env.body = _decodeGetDiagnosticsSnapshot(sub);
          break;
        case 31:
          env.body = _decodeDiagnosticsSnapshot(sub);
          break;
        case 32:
          env.body = _decodeInjectDiagnosticsTestEvent(sub);
          break;
        case 33:
          env.body = _decodeGetProcessDetails(sub);
          break;
        case 34:
          env.body = _decodeProcessDetails(sub);
          break;
        case 35:
          env.body = _decodeGetTimelineEventDetail(sub);
          break;
        case 36:
          env.body = _decodeTimelineEventDetail(sub);
          break;
        case 37:
          env.body = _decodeGetInventoryDomain(sub);
          break;
        case 38:
          env.body = _decodeInventoryDomainSnapshot(sub);
          break;
        case 39:
          env.body = _decodeGetCrashHistory(sub);
          break;
        case 40:
          env.body = _decodeCrashHistory(sub);
          break;
        case 41:
          env.body = _decodeListEventLogChannels(sub);
          break;
        case 42:
          env.body = _decodeEventLogChannelList(sub);
          break;
        case 43:
          env.body = _decodeSetTrackedChannels(sub);
          break;
        case 44:
          env.body = _decodeTrackedChannels(sub);
          break;
        case 99:
          env.body = _decodeError(sub);
          break;
      }
    } else {
      r.skip(wire);
    }
  }
  return env;
}

Uint8List encodeFrame(Uint8List payload) {
  if (payload.length > 2 * 1024 * 1024) {
    throw StateError('payload exceeds 2 MB');
  }
  final out = Uint8List(8 + payload.length);
  out[0] = 0x50;
  out[1] = 0x55;
  out[2] = 0x4C;
  out[3] = 0x53;
  final len = payload.length;
  out[4] = len & 0xff;
  out[5] = (len >> 8) & 0xff;
  out[6] = (len >> 16) & 0xff;
  out[7] = (len >> 24) & 0xff;
  out.setRange(8, out.length, payload);
  return out;
}

class FrameDecodeResult {
  FrameDecodeResult({required this.payload, required this.consumed});
  final Uint8List payload;
  final int consumed;
}

FrameDecodeResult? tryDecodeFrame(Uint8List data) {
  if (data.length < 8) return null;
  if (data[0] != 0x50 || data[1] != 0x55 || data[2] != 0x4C || data[3] != 0x53) {
    throw FormatException('invalid frame magic');
  }
  final plen = data[4] | (data[5] << 8) | (data[6] << 16) | (data[7] << 24);
  if (plen > 2 * 1024 * 1024) {
    throw FormatException('frame exceeds 2 MB');
  }
  if (data.length < 8 + plen) return null;
  return FrameDecodeResult(
    payload: data.sublist(8, 8 + plen),
    consumed: 8 + plen,
  );
}
