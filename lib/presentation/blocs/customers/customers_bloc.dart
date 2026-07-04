import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'customers_event.dart';
import 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final DataRepository repository;

  CustomersBloc({required this.repository}) : super(CustomersInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomer>(_onAddCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomersState> emit,
  ) async {
    emit(CustomersLoading());
    try {
      final customers = await repository.getCustomersByVillage(
        event.villageLocalId,
      );
      emit(CustomersLoaded(customers));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomersState> emit,
  ) async {
    try {
      await repository.addCustomer(
        villageLocalId: event.villageLocalId,
        name: event.name,
        phone: event.phone,
        houseNumber: event.houseNumber,
        address: event.address,
      );
      // Reload customers after adding
      add(LoadCustomers(event.villageLocalId));
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }
}
