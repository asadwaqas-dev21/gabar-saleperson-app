abstract class InventoryState {}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Map<String, dynamic>> items;

  InventoryLoaded({required this.items});
}

class InventoryError extends InventoryState {
  final String message;

  InventoryError({required this.message});
}
