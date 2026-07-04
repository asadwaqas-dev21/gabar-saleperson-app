import 'package:equatable/equatable.dart';

abstract class VillagesEvent extends Equatable {
  const VillagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadVillages extends VillagesEvent {}

class AddVillage extends VillagesEvent {
  final String name;
  final String? notes;

  const AddVillage({required this.name, this.notes});

  @override
  List<Object?> get props => [name, notes];
}
