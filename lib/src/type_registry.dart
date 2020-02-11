import 'dart:math';

import 'package:meta/meta.dart';

import 'adapters/adapters.dart';
import 'binary.dart';
import 'type_node.dart';

part 'adapter.dart';

void debugPrint(Object object) => print(object);

class LegacyTypeUsed implements Exception {
  LegacyTypeUsed(this.id, this.adapter);

  final int id;
  final AdapterFor<dynamic> adapter;

  String toString() => 'The id $id is marked as legacy and should not be used '
      'anymore. However, the adapter $adapter registered for that id.';
}

/// The [TypeRegistry] holds references to all [AdapterFor]s used to serialize
/// and deserialize data.
///
/// It allows getting an adapter by id, getting the id of an adapter, as well
/// as finding an adapter for a specific object.
final TypeRegistry = TypeRegistryImpl._();

class TypeRegistryImpl {
  TypeRegistryImpl._() {
    registerBuiltInAdapters(this);
    _adapterTree.debugDump();
  }

  // For greater efficiency, there are several data structures that hold
  // references to adapters. These allow us to:
  // - Get the id of an adapter in O(1).
  // - Get an adapter for an id in O(1).
  // - If the static type of an object equals its runtime type, getting the
  //   correct adapter for that object in O(1).
  // - If the static type of an object differs from its runtime type, getting
  //   the correct adapter somewhere between O(log n) and O(n), depending on
  //   the class hierarchy.
  final _idsByAdapters = <AdapterFor<dynamic>, int>{};
  final _adaptersById = <int, AdapterFor<dynamic>>{};

  final _adapterShortcuts = <Type, AdapterNode<dynamic>>{};
  final _adapterTree = AdapterNode<Object>.virtual();

  /// Users may register adapters for types in one version of their app and
  /// later remove types and the corresponding adapters. To ensure
  /// interoperability between encodings created at different versions of the
  /// app, ids should not be reused at some later time.
  final _legacyIds = <int>{};

  /// If an exact type can't be encoded, we suggest adding an adapter. Here, we
  /// keep track of which adapters we suggested along with the suggested id.
  final _suggestedAdapters = <String, int>{};

  /// Register a virtual [AdapterNode] to make it available for serializing and
  /// deserializing.
  void registerVirtualNode<T>(AdapterNode<T> node) {
    assert(node != null);
    assert(node.isVirtual);

    _adapterShortcuts[node.type] ??= node;
    _adapterTree.insert(node);
  }

  /// Register a [AdapterFor<T>] to make it available for serializing and
  /// deserializing.
  void registerAdapter<T>(
    int typeId,
    AdapterFor<T> adapter, {
    bool showWarningForSubtypes = true,
  }) {
    assert(typeId != null);
    assert(adapter != null);
    assert(showWarningForSubtypes != null);

    if (_legacyIds.contains(typeId)) {
      throw LegacyTypeUsed(typeId, adapter);
    }

    if (_idsByAdapters[adapter] == typeId) {
      debugPrint('You tried to register adapter $adapter, but its already '
          'registered under that id ($typeId).');
      return;
    }

    final adapterForId = _adaptersById[typeId];
    if (adapterForId != null && adapterForId != adapter) {
      debugPrint('You tried to register $adapter under id $typeId, but there '
          'is already a different adapter registered under that id: '
          '$adapterForId');
    }

    _idsByAdapters[adapter] = typeId;
    _adaptersById[typeId] = adapter;

    final node = AdapterNode<T>(
      adapter: adapter,
      showWarningForSubtypes: showWarningForSubtypes,
    );

    _adapterShortcuts[adapter.type] ??= node;
    _adapterTree.insert(node);
  }

  /// Register multiple adapters.
  void registerAdapters(
    Map<int, AdapterFor<dynamic>> adaptersById, {
    bool showWarningForSubtypes = true,
  }) {
    // We don't directly call [registerAdapter], but rather let the adapter
    // call that method, because otherwise we would lose type information (the
    // static type of the adapters inside the map is `TypeAdapter<dynamic>`).
    adaptersById.forEach((typeId, adapter) {
      adapter._registerForId(typeId, this,
          showWarningForSubtypes: showWarningForSubtypes);
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
  int findIdOfAdapter(AdapterFor<dynamic> adapter) => _idsByAdapters[adapter];

  /// Finds the adapter registered for the given [typeId].
  AdapterFor<dynamic> findAdapterById(int typeId) => _adaptersById[typeId];

  /// Finds an adapter for serializing the [object].
  AdapterFor<T> findAdapterByValue<T>(T object) {
    // Find the best matching adapter in the type tree.
    final searchStartNode =
        _adapterShortcuts[object.runtimeType] ?? _adapterTree;
    final matchingNode = searchStartNode.findNodeByValue(object);
    final matchingType = matchingNode.type;
    final actualType = object.runtimeType;

    if (matchingNode.adapter == null) {
      throw Exception('No adapter for the type $actualType found. Consider '
          'adding an adapter for that type by calling '
          '${_createAdapterSuggestion(actualType)}.');
    }

    if (matchingNode.showWarningForSubtypes &&
        !_isSameType(actualType, matchingType)) {
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
