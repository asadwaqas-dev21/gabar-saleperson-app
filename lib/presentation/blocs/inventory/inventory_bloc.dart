import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final DataRepository repository;

  InventoryBloc({required this.repository}) : super(InventoryInitial()) {
    on<LoadInventory>(_onLoadInventory);
  }

  Future<void> _onLoadInventory(
    LoadInventory event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final items = await repository.localDataSource.getJoinedInventory();
      emit(InventoryLoaded(items: items));
    } catch (e) {
      emit(InventoryError(message: 'Failed to load inventory: \$e'));
    }
  }
}
