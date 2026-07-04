import 'package:equatable/equatable.dart';

abstract class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomersEvent {
  final String villageLocalId;

  const LoadCustomers(this.villageLocalId);

  @override
  List<Object?> get props => [villageLocalId];
}

class AddCustomer extends CustomersEvent {
  final String villageLocalId;
  final String name;
  final String phone;
  final String houseNumber;
  final String address;

  const AddCustomer({
    required this.villageLocalId,
    required this.name,
    required this.phone,
    required this.houseNumber,
    required this.address,
  });

  @override
  List<Object?> get props => [villageLocalId, name, phone, houseNumber, address];
}
