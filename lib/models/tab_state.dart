/// Manages the collection of open tabs
class TabManagerState {
  final List<String> tabIds;
  final int activeTabIndex;
  /// Monotonic counter bumped on document content changes to ensure
  /// Riverpod detects state updates even when tabIds/activeTabIndex are unchanged.
  final int revision;

  const TabManagerState({
    this.tabIds = const [],
    this.activeTabIndex = -1,
    this.revision = 0,
  });

  /// Whether there are any open tabs
  bool get hasTabs => tabIds.isNotEmpty;

  /// The active tab ID, or null if no tabs are open
  String? get activeTabId =>
      activeTabIndex >= 0 && activeTabIndex < tabIds.length
          ? tabIds[activeTabIndex]
          : null;

  /// Number of open tabs
  int get tabCount => tabIds.length;

  TabManagerState copyWith({
    List<String>? tabIds,
    int? activeTabIndex,
    int? revision,
  }) {
    return TabManagerState(
      tabIds: tabIds ?? this.tabIds,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      revision: revision ?? this.revision,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabManagerState &&
          runtimeType == other.runtimeType &&
          activeTabIndex == other.activeTabIndex &&
          revision == other.revision &&
          _listEquals(tabIds, other.tabIds);

  @override
  int get hashCode => Object.hash(activeTabIndex, revision, Object.hashAll(tabIds));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
