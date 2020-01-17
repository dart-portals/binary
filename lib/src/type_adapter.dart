import 'package:meta/meta.dart';

import 'source.dart';
import 'type_registry.dart';

typedef Writer<T> = void Function(BinaryWriter writer, T obj);
typedef Reader<T> = T Function(BinaryReader reader);
typedef SubTypeAdapterBuilder<T> = TypeAdapter<T> Function();

/// [TypeAdapter]s can be implemented to support serializing and deserializing
/// Dart objects of type [T].
@immutable
abstract class TypeAdapter<T> {
  const TypeAdapter();

  Type get type => T;
  bool matches(dynamic value) => value is T;

  void write(BinaryWriter writer, T obj);
  T read(BinaryReader reader);

  /// Registers this adapter for the given [typeId].
  void registerForId(int typeId) =>
      TypeRegistry.registerAdapter<T>(typeId, this);
}
