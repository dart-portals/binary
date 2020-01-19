import 'dart:convert';
import 'dart:typed_data';

import '../source.dart';
import '../type_registry.dart';

part 'core.dart';
part 'collections.dart';
part 'custom.dart';
part 'typed_data.dart';

const builtInAdapters = <int, TypeAdapter<dynamic>>{
  // dart:core adapters.
  -18: AdapterForNull(),
  -4: AdapterForBool(),
  -5: AdapterForDouble(),
  -6: AdapterForInt(),
  -7: AdapterForString(),
  -8: AdapterForBigInt(),
  -9: AdapterForDateTime(),
  -10: AdapterForDuration(),
  -15: AdapterForRegExp(),
  -16: AdapterForRunes(),
  -17: AdapterForStackTrace(),

  // dart:core collection adapters.
  -11: AdapterForList(),
  -19: AdapterForPrimitiveList<Null>(AdapterForNull()),
  -20: AdapterForPrimitiveList<bool>(AdapterForBool()),
  -2: AdapterForPrimitiveList<double>(AdapterForDouble()),
  -21: AdapterForPrimitiveList<int>(AdapterForInt()),
  -1: AdapterForPrimitiveList<String>(AdapterForString()),
  -12: AdapterForSet(),
  -13: AdapterForMapEntry(),
  -14: AdapterForMap(),
  -22: AdapterForMapWithPrimitiveKey<double, dynamic>(AdapterForDouble()),
  -23: AdapterForMapWithPrimitiveKey<int, dynamic>(AdapterForInt()),
  -24: AdapterForMapWithPrimitiveKey<String, dynamic>(AdapterForString()),

  // dart:typed_data adapters.
  -3: AdapterForUint8List(),
};
