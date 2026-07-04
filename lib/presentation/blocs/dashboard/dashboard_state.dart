import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final double todaySales;
  final double collection;
  final double pending;
  final int villagesCount;
  final int customersCount;
  final int inventoryLeft;
  final int pendingSync;
  final String salespersonName;
  final List<Map<String, dynamic>> followUps;

  const DashboardLoaded({
    required this.todaySales,
    required this.collection,
    required this.pending,
    required this.villagesCount,
    required this.customersCount,
    required this.inventoryLeft,
    required this.pendingSync,
    required this.salespersonName,
    required this.followUps,
  });

  @override
  List<Object> get props => [
        todaySales,
        collection,
        pending,
        villagesCount,
        customersCount,
        inventoryLeft,
        pendingSync,
        salespersonName,
        followUps,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}
