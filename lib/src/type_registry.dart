import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';

import 'adapters/adapters.dart';
import 'binary.dart';
import 'type_node.dart';

part 'type_adapter.dart';

void debugPrint(Object object) => print(object);

class LegacyTypeUsed implements Exception {
  LegacyTypeUsed(this.id, this.adapter);

  final int id;
  final TypeAdapter<dynamic> adapter;

  String toString() => 'The id $id is marked as legacy and should not be used '
      'anymore. However, the adapter $adapter registered for that id.';
}

/// The [TypeRegistry] holds references to all [TypeAdapter]s used to serialize
/// and deserialize data.
///
/// It allows getting an adapter by id, getting the id of an adapter, as well
/// as finding an adapter for a specific object.
final TypeRegistry = _TypeRegistryImpl._()..registerAdapters(builtInAdapters);

class _TypeRegistryImpl {
  _TypeRegistryImpl._();

  void thenDo(void Function() callback) => scheduleMicrotask(callback);

  // For greater efficiency, there are several data structures that hold
  // references to adapters. These allow us to:
  // - Get the id of an adapter in O(1).
  // - Get an adapter for an id in O(1).
  // - If the static type of an object equals its runtime type, getting the
  //   correct adapter for that object in O(1).
  // - If the static type of an object differs from its runtime type, getting
  //   the correct adapter somewhere between O(log n) and O(n), depending on
  //   the class hierarchy.
  final _idsByAdapters = <TypeAdapter<dynamic>, int>{};
  final _adaptersById = <int, TypeAdapter<dynamic>>{};
  final _adaptersByExactType = <Type, TypeAdapter<dynamic>>{};
  final _typeTree = TypeNode<Object>.virtual()
    ..addSubtype(TypeNode<Iterable>.virtual());

  // Users may register adapters for types in one version of their app and
  // later remove types and the corresponding adapters. To ensure
  // interoperability between encodings created at different versions of the
  // app, ids should not be reused at some later time.
  final _legacyIds = <int>{};

  // If an exact type can't be encoded, we suggest adding an adapter. Here, we
  // keep track of which adapters we suggested along with the suggested id.
  final _suggestedAdapters = <String, int>{};

  /// Register a [TypeAdapter] to make it available for serializing and
  /// deserializing.
  void registerAdapter<T>(int typeId, TypeAdapter<T> adapter) {
    assert(typeId != null);
    assert(adapter != null);

    if (_legacyIds.contains(typeId)) {
      throw LegacyTypeUsed(typeId, adapter);
    }

    if (_idsByAdapters[adapter] == typeId) {
      debugPrint('You tried to register adapter $adapter, but its already '
          'registered under that id ($typeId).');
      return;
    }

    final adapterForType = _adaptersByExactType[adapter.type];
    if (adapterForType != null && adapterForType != adapter) {
      debugPrint('You tried to register adapter $adapter for type '
          '${adapter.type}, but for that type there is already adapter '
          '$adapterForType registered.');
    }

    final adapterForId = _adaptersById[typeId];
    if (adapterForId != null && adapterForId != adapter) {
      debugPrint('You tried to register $adapter under id $typeId, but there '
          'is already a different adapter registered under that id: '
          '$adapterForId');
    }

    _idsByAdapters[adapter] = typeId;
    _adaptersById[typeId] = adapter;
    _adaptersByExactType[adapter.type] = adapter;
    _typeTree.insert(TypeNode<T>(adapter));
  }

  /// Register multiple adapters.
  void registerAdapters(Map<int, TypeAdapter<dynamic>> adaptersById) {
    // We don't directly call [registerAdapter], but rather let the adapter
    // call that method, because otherwise we would lose type information (the
    // static type of the adapters inside the map is `TypeAdapter<dynamic>`).
    adaptersById.forEach((typeId, adapter) {
      adapter._registerForId(typeId, this);
    });
  }

  /// Make sure the [typeIds] are not being used anymore.
  void registerLegacyTypes(Set<int> typeIds) {
    _legacyIds.addAll(typeIds);

    final usedIds = typeIds.intersection(_adaptersById.keys.toSet());
    if (usedIds.isNotEmpty) {
      throw LegacyTypeUsed(usedIds.first, _adaptersById[usedIds.first]);
    }
  }

  /// Finds the id of an adapter.
  int findIdOfAdapter(TypeAdapter<dynamic> adapter) => _idsByAdapters[adapter];

  /// Finds the adapter registered for the given [typeId].
  TypeAdapter findAdapterById(int typeId) => _adaptersById[typeId];

  /// Finds an adapter for serializing the [object].
  TypeAdapter findAdapterByValue<T>(T object) {
    // First, try to find an adapter by the exact type in O(1).
    final adapterForExactType = _adaptersByExactType[object.runtimeType];
    if (adapterForExactType != null) {
      return adapterForExactType;
    }

    // Otherwise, find the best matching adapter in the type tree.
    final matchingNode = _typeTree.findNodeByValue(object);
    final matchingType = matchingNode.type;
    final actualType = object.runtimeType;

    if (matchingNode.adapter == null) {
      throw Exception('No adapter for the type $actualType found. Consider '
          'adding an adapter for that type by calling '
          '${_createAdapterSuggestion(actualType)}.');
    }

    if (!_isSameType(actualType, matchingType)) {
      debugPrint('No adapter for the exact type $actualType found, so we\'re '
          'encoding it as a $matchingNode. For better performance and truly '
          'type-safe serializing, consider adding an adapter for that type by '
          'calling ${_createAdapterSuggestion(actualType)}.');
    }

    return matchingNode.adapter;
  }

  static bool _isSameType(Type runtimeType, Type staticType) {
    return staticType.toString() ==
        runtimeType
            .toString()
            .replaceAll('JSArray', 'List')
            .replaceAll('_CompactLinkedHashSet', 'Set');
  }

  String _createAdapterSuggestion(Type type) {
    final suggestedId = _suggestedAdapters[type.toString()] ??
        _adaptersById.keys.reduce(max) + 1 + _suggestedAdapters.length;
    _suggestedAdapters[type.toString()] = suggestedId;

    return 'AdapterFor$type().registerForId($suggestedId)';
  }
}
