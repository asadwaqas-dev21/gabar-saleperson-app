abstract class CustomerProfileEvent {}

class LoadCustomerProfileData extends CustomerProfileEvent {
  final String customerLocalId;
  LoadCustomerProfileData(this.customerLocalId);
}
