/// Comparison operations for sets.
extension SetComparison<T> on Set<T> {
  /// Returns whether this set and [other] contain the same elements.
  bool hasSameElementsAs(Set<T> other) =>
      length == other.length && containsAll(other);
}
