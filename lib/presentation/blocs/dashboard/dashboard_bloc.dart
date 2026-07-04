import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DataRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboardData>((event, emit) async {
      emit(DashboardLoading());
      
      try {
        final stats = await repository.getDashboardStats();
        final followUps = await repository.getFollowUps();
        final profile = await repository.getSalespersonProfile();
        
        emit(DashboardLoaded(
          todaySales: stats['todaySales'] as double,
          collection: stats['collection'] as double,
          pending: stats['pending'] as double,
          villagesCount: stats['villagesCount'] as int,
          customersCount: stats['customersCount'] as int,
          inventoryLeft: stats['inventoryLeft'] as int,
          pendingSync: stats['pendingSync'] as int,
          salespersonName:
              profile?['name']?.toString().trim().isNotEmpty == true
                  ? profile!['name'].toString()
                  : 'Salesperson',
          followUps: followUps,
        ));
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    });
  }
}
