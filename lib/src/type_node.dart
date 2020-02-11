import 'package:meta/meta.dart';

import 'type_registry.dart';

/// Adapters are saved in a tree of [AdapterNode]s for efficient lookup.
///
/// A tree structure allows us to have different adapters based on the type and
/// the value. In contrast to resolving adapters statically by type, this
/// allows more flexibility when choosing the adapter:
/// - An adapter might be able to encode a `SampleClass` and all its
///   subclasses, so there don't need to be adapters for the subclasses.
/// - An adapter might decide to encode different *values* differently. For
///   example, integers that match the constraints of uint8, int 8, uint16, etc
///   all might be encoded differently.
/// - Some types cannot be known statically. For example, `<int>[].runtimeType`
///   is not the same `List<int>` as a static `List<int>`. At runtime, it's
///   either a `List<int>` or a `JSArray`.
///
/// That being said, there exist shortcuts into the tree based on the runtime
/// type.
class AdapterNode<T> {
  AdapterNode({
    @required this.adapter,
    this.showWarningForSubtypes = true,
  }) : assert(showWarningForSubtypes != null);

  AdapterNode.virtual() : this(adapter: null);

  /// The adapter registered for this type node.
  final AdapterFor<T> adapter;
  bool get isVirtual => adapter == null;

  /// Whether to show warnings for subtypes. If [true] and values do not match
  /// this [AdapterNode] exactly, a warning will be outputted to the console.
  /// For example, if the developer tries to encode a `SomeType<int>`, but the
  /// only [AdapterNode] found is one of `SomeType<dynamic>`, a warning will be
  /// logged in the console if [showWarningForSubtypes] is [true].
  final bool showWarningForSubtypes;

  /// [AdapterNode]s of subtypes.
  final _children = <AdapterNode<T>>{};

  Type get type => T;

  bool matches(dynamic value) {
    if (value is! T) {
      return false;
    }
    if (adapter is AdapterForSpecificValueOfType) {
      return (adapter as AdapterForSpecificValueOfType).matches(value);
    }
    return true;
  }

  bool isSupertypeOf(AdapterNode<dynamic> node) {
    final isValueNode =
        adapter != null && adapter is AdapterForSpecificValueOfType;
    return !isValueNode && node is AdapterNode<T>;
  }

  void addNode(AdapterNode<T> type) => _children.add(type);
  void addSubNodes(Iterable<AdapterNode<dynamic>> types) =>
      _children.addAll(types.cast<AdapterNode<T>>());

  void insert(AdapterNode<T> newNode) {
    final parentNodes = _children.where((type) => type.isSupertypeOf(newNode));

    if (parentNodes.isNotEmpty) {
      for (final subtype in parentNodes) {
        subtype.insert(newNode);
      }
    } else {
      final typesUnderNewType = _children.where(newNode.isSupertypeOf).toList();
      _children.removeAll(typesUnderNewType);
      newNode.addSubNodes(typesUnderNewType);
      _children.add(newNode);
    }
  }

  AdapterNode<T> findNodeByValue(T value) {
    final matchingSubNode = _children.firstWhere(
      (type) => type.matches(value),
      orElse: () => null,
    );
    return matchingSubNode?.findNodeByValue(value) ?? this;
  }

  void debugDump() {
    final buffer = StringBuffer();
    buffer.write('root node for objects to serialize\n');
    final children = _children;

    for (final child in children) {
      buffer.write(child._debugToString('', child == children.last));
    }
    print(buffer);
  }

  String _debugToString(String prefix, bool isLast) {
    final children = _children.toList();
    return [
      prefix,
      if (isVirtual)
        '${isLast ? '└─' : '├─'} virtual node for $type'
      else
        '${isLast ? '└─' : '├─'} ${adapter.runtimeType}',
      '\n',
      for (final child in children)
        child._debugToString(
            '$prefix${isLast ? '   ' : '│  '}', child == children.last),
    ].join();
  }
}
