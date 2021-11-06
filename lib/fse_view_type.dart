enum FseViewType {
  grid,
  list,
}

extension FseViewTypeExtension on FseViewType {
  FseViewType get next {
    return FseViewType.values[(1 + index) % FseViewType.values.length];
  }
}
