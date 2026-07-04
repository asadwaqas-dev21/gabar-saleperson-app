import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'customer_profile_event.dart';
import 'customer_profile_state.dart';

class CustomerProfileBloc extends Bloc<CustomerProfileEvent, CustomerProfileState> {
  final DataRepository repository;

  CustomerProfileBloc({required this.repository}) : super(CustomerProfileInitial()) {
    on<LoadCustomerProfileData>((event, emit) async {
      emit(CustomerProfileLoading());
      try {
        final customer = await repository.getCustomerByLocalId(event.customerLocalId);
        final sales = await repository.getSalesByCustomer(event.customerLocalId);
        final payments = await repository.localDataSource.getPaymentsByCustomer(event.customerLocalId);
        
        if (customer == null) {
          emit(CustomerProfileError('Customer not found'));
          return;
        }

        emit(CustomerProfileLoaded(
          customer: customer,
          sales: sales,
          payments: payments,
        ));
      } catch (e) {
        emit(CustomerProfileError(e.toString()));
      }
    });
  }
}
