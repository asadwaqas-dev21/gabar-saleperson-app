import 'package:equatable/equatable.dart';
import 'package:salesperson_app/data/models/customer_model.dart';

abstract class CustomersState extends Equatable {
  const CustomersState();
  
  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {}

class CustomersLoading extends CustomersState {}

class CustomersLoaded extends CustomersState {
  final List<CustomerModel> customers;

  const CustomersLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

class CustomersError extends CustomersState {
  final String message;

  const CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}
