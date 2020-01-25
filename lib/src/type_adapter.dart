part of 'type_registry.dart';

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
  void registerForId(int typeId) => _registerForId(typeId, TypeRegistry);

  /// Registers this adapter for the given [typeId] on the given [registry].
  void _registerForId(int typeId, _TypeRegistryImpl registry) =>
      registry.registerAdapter<T>(typeId, this);

  /// [TypeAdapter]s should have no internal state/fields whatsoever.
  /// To clients, they should be merely a wrapper class around the [write] and
  /// [read] method. That's why if you create two adapters of the same type,
  /// they should be equal. We explicitly encode that here so that users don't
  /// get weird errors if they try to register the "same" adapter twice:
  ///
  /// ```dart
  /// AdapterForSomething().registerForId(0);
  /// AdapterForSomething().registerForId(0); // Should not throw an error.
  /// ```
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType;
  }
}
