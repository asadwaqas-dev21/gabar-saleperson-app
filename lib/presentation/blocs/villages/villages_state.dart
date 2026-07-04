import 'package:equatable/equatable.dart';
import 'package:salesperson_app/data/models/village_model.dart';

abstract class VillagesState extends Equatable {
  const VillagesState();
  
  @override
  List<Object?> get props => [];
}

class VillagesInitial extends VillagesState {}

class VillagesLoading extends VillagesState {}

class VillagesLoaded extends VillagesState {
  final List<VillageModel> villages;
  final List<Map<String, dynamic>> summaries;

  const VillagesLoaded(this.villages, {this.summaries = const []});

  @override
  List<Object?> get props => [villages, summaries];
}

class VillagesError extends VillagesState {
  final String message;

  const VillagesError(this.message);

  @override
  List<Object?> get props => [message];
}
