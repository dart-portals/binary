part of 'type_registry.dart';

typedef Writer<T> = void Function(BinaryWriter writer, T obj);
typedef Reader<T> = T Function(BinaryReader reader);
typedef SubTypeAdapterBuilder<T> = AdapterFor<T> Function();

/// [AdapterFor]s can be implemented to support serializing and deserializing
/// Dart objects of type [T].
@immutable
abstract class AdapterFor<T> {
  const AdapterFor() : _isPrimitive = false;
  const AdapterFor.primitive() : _isPrimitive = true;

  Type get type => T;

  /// Whether this is a primitive adapter. Primitive adapters allow for more
  /// efficiency by not saving the length of the serialized data in the binary
  /// format. So, primitive adapters may not call [BinaryReader.availableBytes]
  /// or [BinaryReader.hasAvailableBytes].
  /// That means primitive adapters cannot have faulty behavior – otherwise
  /// they may corrupt some of the binary format around them. Primitive
  /// adapters always have to be registered – trying to deserialize a binary
  /// format that contains such a type without the adapter being registered
  /// makes the binary format being considered corrupted.
  final bool _isPrimitive;
  bool get isPrimitive => _isPrimitive;

  void write(BinaryWriter writer, T obj);
  T read(BinaryReader reader);

  /// Registers this adapter for the given [typeId].
  void registerForId(
    int typeId, {
    bool showWarningForSubtypes = true,
  }) =>
      _registerForId(typeId, TypeRegistry,
          showWarningForSubtypes: showWarningForSubtypes);

  /// Registers this adapter for the given [typeId] on the given [registry].
  void _registerForId(
    int typeId,
    TypeRegistryImpl registry, {
    @required bool showWarningForSubtypes,
  }) =>
      registry.registerAdapter<T>(
        typeId,
        this,
        showWarningForSubtypes: showWarningForSubtypes,
      );

  /// [AdapterFor]s should have no internal state/fields whatsoever.
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

  String toString() => runtimeType.toString();
}

abstract class AdapterForSpecificValueOfType<T> extends AdapterFor<T> {
  const AdapterForSpecificValueOfType() : super();
  const AdapterForSpecificValueOfType.primitive() : super.primitive();

  bool matches(T value);
}
