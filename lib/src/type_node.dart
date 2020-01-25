import 'type_registry.dart';

/// Adapters are saved in a tree of [TypeNode]s for efficient lookup.
///
/// ## Why can't we resolve adapters statically by type?
///
/// Most of the time when using adapters, we don't need to look at this tree at
/// all – rather we can directly look up the adapter in a
/// `Map<Type, TypeAdapter<dynamic>>`.
/// Sometimes however, that doesn't work. The reason is that in Dart, the
/// static and runtime type can differ – consider the following example:
///
/// ```
/// Type typeOf<T>() => T;
/// print(<int>[1,2,3].runtimeType == typeOf<List<int>>()); // false
/// ```
///
/// Although both `<int>[1,2,3].runtimeType` and `typeOf<List<int>>()` evaluate
/// to `List<int>` when printed as a String, these are different `List<int>`s.
/// The reason for that is underlying optimizations. For example, on the web,
/// `<int>[1,2,3].runtimeType` evaluates to `JSArray` – you can try that on
/// [DartPad](https://dartpad.dev).
class TypeNode<T> {
  TypeNode(this.adapter);
  TypeNode.virtual() : this(null);

  final TypeAdapter<T> adapter;
  final _subtypes = <TypeNode<T>>{};

  Type get type => T;

  bool matches(dynamic value) => value is T;
  bool isSupertypeOf(TypeNode<dynamic> type) => type is TypeNode<T>;

  void addSubtype(TypeNode<T> type) => _subtypes.add(type);
  void addSubtypes(Iterable<TypeNode<dynamic>> types) =>
      _subtypes.addAll(types.cast<TypeNode<T>>());

  void insert(TypeNode<T> newType) {
    final typesOverNewType =
        _subtypes.where((type) => type.isSupertypeOf(newType));

    if (typesOverNewType.isNotEmpty) {
      for (final subtype in typesOverNewType) {
        subtype.insert(newType);
      }
    } else {
      final typesUnderNewType =
          _subtypes.where((type) => newType.isSupertypeOf(type)).toList();
      _subtypes.removeAll(typesUnderNewType);
      newType.addSubtypes(typesUnderNewType);
      _subtypes.add(newType);
    }
  }

  TypeNode<T> findNodeByValue(T value) {
    final matchingSubtype =
        _subtypes.firstWhere((type) => type.matches(value), orElse: () => null);
    return matchingSubtype?.findNodeByValue(value) ?? this;
  }
}
