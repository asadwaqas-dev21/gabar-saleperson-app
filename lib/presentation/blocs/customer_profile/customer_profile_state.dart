import 'package:salesperson_app/data/models/sale_model.dart';
import 'package:salesperson_app/data/models/payment_model.dart';
import 'package:salesperson_app/data/models/customer_model.dart';

abstract class CustomerProfileState {}

class CustomerProfileInitial extends CustomerProfileState {}

class CustomerProfileLoading extends CustomerProfileState {}

class CustomerProfileLoaded extends CustomerProfileState {
  final List<SaleModel> sales;
  final List<PaymentModel> payments;
  final CustomerModel customer;

  CustomerProfileLoaded({
    required this.sales,
    required this.payments,
    required this.customer,
  });
}

class CustomerProfileError extends CustomerProfileState {
  final String message;

  CustomerProfileError(this.message);
}
