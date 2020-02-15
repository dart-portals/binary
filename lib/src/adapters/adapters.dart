import 'dart:convert';
import 'dart:typed_data';

import 'package:binary/binary.dart';
import 'package:meta/meta.dart';

import '../binary.dart';
import '../type_node.dart';
import '../type_registry.dart';

part 'big_int.dart';
part 'bool.dart';
part 'core.dart';
part 'custom.dart';
part 'int.dart';
part 'list.dart';
part 'map.dart';
part 'set.dart';
part 'string.dart';
part 'typed_data.dart';

void registerBuiltInAdapters(TypeRegistryImpl registry) {
  // Commonly used nodes should be registered first for more efficiency.
  registry.registerVirtualNode(AdapterNode<Iterable<dynamic>>.virtual());

  // dart:core adapters
  _registerCoreAdapters(registry);

  // dart:typed_data adapters
  _registerTypedDataAdapters(registry);
}

void _registerCoreAdapters(TypeRegistryImpl registry) {
  // null adapter
  registry.registerAdapter(-101, AdapterForNull());

  // int adapters
  registry.registerVirtualNode(AdapterNode<int>.virtual());
  registry.registerAdapters({
    -1: AdapterForUint8(),
    -2: AdapterForInt8(),
    -3: AdapterForUint16(),
    -4: AdapterForInt16(),
    -5: AdapterForUint32(),
    -6: AdapterForInt32(),
    -7: AdapterForInt64(),
  });

  // double adapter
  registry.registerAdapter(-8, AdapterForDouble());

  // bool adapters
  registry.registerVirtualNode(AdapterNode<bool>.virtual());
  registry.registerAdapters({
    -9: AdapterForTrueBool(),
    -10: AdapterForFalseBool(),
  });

  // string adapters
  registry.registerVirtualNode(AdapterNode<String>.virtual());
  registry.registerAdapters({
    -11: AdapterForNullTerminatedString(),
    -12: AdapterForArbitraryString(),
  });

  // various other adapters for primitive types
  registry.registerAdapters({
    -13: AdapterForBigInt(),
    -14: AdapterForDateTime(),
    -15: AdapterForDuration(),
    -16: AdapterForRegExp(),
    -17: AdapterForRunes(),
    -18: AdapterForStackTrace(),
  });

  // list adapters
  registry.registerAdapters({
    -19: AdapterForList<dynamic>(),
    -20: AdapterForListOfNull(),
    -21: AdapterForListOfBool(),
  });
  registry.registerVirtualNode(AdapterNode<List<String>>.virtual());
  registry.registerAdapters({
    -22: AdapterForPrimitiveList<String>.short(AdapterForArbitraryString()),
    -23: AdapterForPrimitiveList<String>.long(AdapterForArbitraryString()),
    -24: AdapterForPrimitiveList<String>.nullable(AdapterForArbitraryString()),
  });
  registry.registerVirtualNode(AdapterNode<List<double>>.virtual());
  registry.registerAdapters({
    -25: AdapterForPrimitiveList.short(AdapterForDouble()),
    -26: AdapterForPrimitiveList.long(AdapterForDouble()),
    -27: AdapterForPrimitiveList.nullable(AdapterForDouble()),
  });
  registry.registerVirtualNode(AdapterNode<List<int>>.virtual());
  registry.registerAdapters({
    -28: AdapterForPrimitiveList.short(AdapterForUint8()),
    -29: AdapterForPrimitiveList.long(AdapterForUint8()),
    -30: AdapterForPrimitiveList.nullable(AdapterForUint8()),
    -31: AdapterForPrimitiveList.short(AdapterForInt8()),
    -32: AdapterForPrimitiveList.long(AdapterForInt8()),
    -33: AdapterForPrimitiveList.nullable(AdapterForInt8()),
    -34: AdapterForPrimitiveList.short(AdapterForUint16()),
    -35: AdapterForPrimitiveList.long(AdapterForUint16()),
    -36: AdapterForPrimitiveList.nullable(AdapterForUint16()),
    -37: AdapterForPrimitiveList.short(AdapterForInt16()),
    -38: AdapterForPrimitiveList.long(AdapterForInt16()),
    -39: AdapterForPrimitiveList.nullable(AdapterForInt16()),
    -40: AdapterForPrimitiveList.short(AdapterForUint32()),
    -41: AdapterForPrimitiveList.long(AdapterForUint32()),
    -42: AdapterForPrimitiveList.nullable(AdapterForUint32()),
    -43: AdapterForPrimitiveList.short(AdapterForInt32()),
    -44: AdapterForPrimitiveList.long(AdapterForInt32()),
    -45: AdapterForPrimitiveList.nullable(AdapterForInt32()),
    -46: AdapterForPrimitiveList.short(AdapterForInt64()),
    -47: AdapterForPrimitiveList.long(AdapterForInt64()),
    -48: AdapterForPrimitiveList.nullable(AdapterForInt64()),
  });
  registry.registerAdapters({
    -49: AdapterForList<BigInt>(),
    -50: AdapterForList<DateTime>(),
    -51: AdapterForList<Duration>(),
    -52: AdapterForList<RegExp>(),
    -53: AdapterForList<Runes>(),
    -54: AdapterForList<StackTrace>(),
  });

  // set adapters
  registry.registerAdapters({
    -55: AdapterForSet<dynamic>(),
    -56: AdapterForSet<Null>(),
    -57: AdapterForSet<bool>(),
    -58: AdapterForSet<String>(),
    -59: AdapterForSet<double>(),
    -60: AdapterForSet<int>(),
    -61: AdapterForSet<BigInt>(),
    -62: AdapterForSet<DateTime>(),
    -63: AdapterForSet<Duration>(),
    -64: AdapterForSet<RegExp>(),
    -65: AdapterForSet<Runes>(),
    -66: AdapterForSet<StackTrace>(),
  });

  // map adapters
  registry.registerAdapters({
    -67: AdapterForMapEntry<dynamic, dynamic>(),
    -68: AdapterForMap<dynamic, dynamic>(),
    -69: AdapterForMap<String, dynamic>(),
    -70: AdapterForMap<String, bool>(),
    -71: AdapterForMap<String, String>(),
    -72: AdapterForMap<String, double>(),
    -73: AdapterForMap<String, int>(),
    -74: AdapterForMap<String, BigInt>(),
    -75: AdapterForMap<String, DateTime>(),
    -76: AdapterForMap<String, Duration>(),
    -77: AdapterForMap<double, dynamic>(),
    -78: AdapterForMap<double, bool>(),
    -79: AdapterForMap<double, String>(),
    -80: AdapterForMap<double, double>(),
    -81: AdapterForMap<double, int>(),
    -82: AdapterForMap<double, BigInt>(),
    -83: AdapterForMap<double, DateTime>(),
    -84: AdapterForMap<double, Duration>(),
    -85: AdapterForMap<int, dynamic>(),
    -86: AdapterForMap<int, bool>(),
    -87: AdapterForMap<int, String>(),
    -88: AdapterForMap<int, double>(),
    -89: AdapterForMap<int, int>(),
    -90: AdapterForMap<int, BigInt>(),
    -91: AdapterForMap<int, DateTime>(),
    -92: AdapterForMap<int, Duration>(),
    -93: AdapterForMap<BigInt, Null>(),
    -94: AdapterForMap<BigInt, bool>(),
    -95: AdapterForMap<BigInt, String>(),
    -96: AdapterForMap<BigInt, double>(),
    -97: AdapterForMap<BigInt, int>(),
    -98: AdapterForMap<BigInt, BigInt>(),
    -99: AdapterForMap<BigInt, DateTime>(),
    -100: AdapterForMap<BigInt, Duration>(),
  });
}

void _registerTypedDataAdapters(TypeRegistryImpl registry) {
  registry.registerAdapters({
    -110: AdapterForUint8List(),
  });
}
