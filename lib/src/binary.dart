import 'dart:typed_data';

import 'type_registry.dart';

part 'binary_reader.dart';
part 'binary_writer.dart';

const binary = _Api();

const _reservedTypeIds = 32768;

class _Api {
  const _Api();

  Uint8List serialize(dynamic object) =>
      (BinaryWriter()..write(object))._dataAsUint8List;
  T deserialize<T>(List<int> data) => BinaryReader(data).read<T>();
}
