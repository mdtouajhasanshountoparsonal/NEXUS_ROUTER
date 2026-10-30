import '../../core/models/device.dart';

const Map<String, String> _vendors = {
  'A4:83:E7': 'Apple, Inc.',
  'F0:18:98': 'Apple, Inc.',
  '3C:22:FB': 'Apple, Inc.',
  '8C:85:90': 'Apple, Inc.',
  'AC:BC:32': 'Apple, Inc.',
  '00:1B:63': 'Apple, Inc.',
  '8C:77:12': 'Samsung Electronics',
  '34:23:87': 'Samsung Electronics',
  '5C:0A:5B': 'Samsung Electronics',
  'D8:44:89': 'Samsung Electronics',
  '38:AA:3C': 'Samsung Electronics',
  'C8:19:F7': 'Samsung Electronics',
  '64:B4:73': 'Xiaomi Communications',
  '78:11:DC': 'Xiaomi Communications',
  '50:8F:4C': 'Xiaomi Communications',
  '8C:BE:BE': 'Xiaomi Communications',
  'F8:A4:5F': 'Xiaomi Communications',
  '00:E0:FC': 'Huawei Technologies',
  '48:46:FB': 'Huawei Technologies',
  '70:72:3C': 'Huawei Technologies',
  '3C:97:0E': 'Intel Corporate',
  '8C:16:45': 'Intel Corporate',
  '9C:B6:D0': 'Intel Corporate',
  'A0:36:9F': 'Intel Corporate',
  '5C:F9:38': 'Dell Inc.',
  'B0:83:FE': 'Dell Inc.',
  '18:66:DA': 'Dell Inc.',
  '3C:D9:2B': 'HP Inc.',
  '9C:B6:54': 'HP Inc.',
  '54:E1:AD': 'Lenovo',
  '68:F7:28': 'Lenovo',
  '1C:87:2C': 'ASUSTek Computer',
  '2C:56:DC': 'ASUSTek Computer',
  '20:6A:8A': 'Acer Inc.',
  '00:16:17': 'Micro-Star International',
  '14:EB:B6': 'TP-Link Systems',
  '50:C7:BF': 'TP-Link Systems',
  '98:DA:C4': 'TP-Link Systems',
  '24:0A:C4': 'Espressif Inc.',
  '84:0D:8E': 'Espressif Inc.',
  '3C:61:05': 'Espressif Inc.',
  '7C:9E:BD': 'Espressif Inc.',
  'A4:CF:12': 'Espressif Inc.',
  '44:65:0D': 'Amazon Technologies',
  '68:54:FD': 'Amazon Technologies',
  'F0:27:2D': 'Amazon Technologies',
  'B0:A7:37': 'Roku, Inc.',
  'D8:31:34': 'Roku, Inc.',
  '1C:3B:F3': 'LG Electronics',
  'C4:36:6C': 'LG Electronics',
  '00:1D:BA': 'Sony Corporation',
  'FC:0F:E6': 'Sony Corporation',
  '00:1B:A9': 'Brother Industries',
  '00:1E:8F': 'Canon Inc.',
  '00:E0:4C': 'Realtek Semiconductor',
  '40:78:6A': 'Motorola Mobility',
  '64:A2:F9': 'OnePlus Technology',
  '94:65:2D': 'OnePlus Technology',
  '5C:1D:8A': 'Oppo Electronics',
  '3C:BD:3E': 'Vivo Communication',
  '5C:5B:35': 'Realme',
  '70:5D:CC': 'Tecno Mobile',
  'C8:3A:35': 'Tenda Technology',
  'A0:40:A0': 'Netgear',
  '1C:7E:E5': 'D-Link',
  'B8:27:EB': 'Raspberry Pi Foundation',
  'DC:A6:32': 'Raspberry Pi Foundation',
  'E4:5F:01': 'Raspberry Pi Foundation',
};

const Set<String> _laptopVendors = {
  'Dell Inc.',
  'HP Inc.',
  'Lenovo',
  'ASUSTek Computer',
  'Acer Inc.',
  'Micro-Star International',
  'Intel Corporate',
};

const Set<String> _phoneVendors = {
  'Apple, Inc.',
  'Samsung Electronics',
  'Xiaomi Communications',
  'Huawei Technologies',
  'Motorola Mobility',
  'OnePlus Technology',
  'Oppo Electronics',
  'Vivo Communication',
  'Realme',
  'Tecno Mobile',
};

const Set<String> _tvVendors = {
  'LG Electronics',
  'Sony Corporation',
  'Roku, Inc.',
};
const Set<String> _printerVendors = {'Brother Industries', 'Canon Inc.'};
const Set<String> _iotVendors = {
  'Espressif Inc.',
  'TP-Link Systems',
  'Amazon Technologies',
  'Raspberry Pi Foundation',
};

bool isLocallyAdministered(String mac) {
  final first = int.tryParse(mac.split(':').first, radix: 16);
  if (first == null) return false;
  return (first & 0x02) != 0;
}

String normalizeMac(String mac) {
  final cleaned = mac.replaceAll('-', ':').toUpperCase();
  return cleaned;
}

String vendorForMac(String mac) {
  final normalized = normalizeMac(mac);
  if (isLocallyAdministered(normalized)) {
    return 'Private / randomized MAC';
  }
  return _vendors[normalized.substring(0, 8)] ?? 'Unknown vendor';
}

DeviceType inferDeviceType(String name, String vendor) {
  final hint = name.toLowerCase();
  if (hint.contains('laptop') ||
      hint.contains('leptop') ||
      hint.contains('macbook') ||
      hint.contains('desktop') ||
      hint.contains('computer') ||
      RegExp(r'\bpc\b').hasMatch(hint)) {
    return DeviceType.laptop;
  }
  if (hint.contains('ipad') || hint.contains('tablet')) {
    return DeviceType.tablet;
  }
  if (hint.contains('phone') || hint.contains('mobile')) {
    return DeviceType.phone;
  }
  if (hint.contains('printer') || hint.contains('print')) {
    return DeviceType.printer;
  }
  if (hint.contains('tv') || hint.contains('television')) {
    return DeviceType.tv;
  }
  if (hint.contains('bulb') ||
      hint.contains('plug') ||
      hint.contains('sensor') ||
      hint.contains('camera') ||
      hint.contains('esp') ||
      hint.contains('tuya') ||
      hint.contains('smart')) {
    return DeviceType.iot;
  }

  if (_laptopVendors.contains(vendor)) return DeviceType.laptop;
  if (_printerVendors.contains(vendor)) return DeviceType.printer;
  if (_tvVendors.contains(vendor)) return DeviceType.tv;
  if (_iotVendors.contains(vendor)) return DeviceType.iot;
  if (_phoneVendors.contains(vendor)) return DeviceType.phone;
  return DeviceType.unknown;
}
