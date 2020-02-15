import 'dart:typed_data';

import 'type_registry.dart';

part 'binary_reader.dart';
part 'binary_writer.dart';

const binary = BinaryApi();

const _reservedTypeIds = 32768;

class BinaryApi {
  const BinaryApi();

  Uint8List serialize(dynamic object) =>
      (BinaryWriter()..write(object))._dataAsUint8List;
  T deserialize<T>(List<int> data) => BinaryReader(data).read<T>();
}
