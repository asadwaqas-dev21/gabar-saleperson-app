import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/data/models/village_model.dart';
import 'package:uuid/uuid.dart';
import 'villages_event.dart';
import 'villages_state.dart';

class VillagesBloc extends Bloc<VillagesEvent, VillagesState> {
  final DataRepository repository;
  final _uuid = const Uuid();

  VillagesBloc({required this.repository}) : super(VillagesInitial()) {
    on<LoadVillages>(_onLoadVillages);
    on<AddVillage>(_onAddVillage);
  }

  Future<void> _onLoadVillages(
    LoadVillages event,
    Emitter<VillagesState> emit,
  ) async {
    if (state is! VillagesLoaded) {
      emit(VillagesLoading());
    }
    try {
      final villages = await repository.getVillages();
      final summaries = await repository.getVillageSummaries();
      emit(VillagesLoaded(villages, summaries: summaries));
    } catch (e) {
      emit(VillagesError(e.toString()));
    }
  }

  Future<void> _onAddVillage(
    AddVillage event,
    Emitter<VillagesState> emit,
  ) async {
    try {
      final village = VillageModel(
        businessId: 'DUMMY_BUSINESS',
        salespersonId: 'DUMMY_SALESPERSON',
        name: event.name,
        notes: event.notes,
        localId: _uuid.v4(),
        syncStatus: 'pending_sync',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.localDataSource.insertVillage(village);

      add(LoadVillages());
    } catch (e) {
      emit(VillagesError(e.toString()));
    }
  }
}
