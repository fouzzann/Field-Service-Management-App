import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  final String period;
  const DashboardState(this.period);

  @override
  List<Object?> get props => [period];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial() : super('All Time');
}

class DashboardPeriodUpdated extends DashboardState {
  const DashboardPeriodUpdated(super.period);
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardInitial());

  void updatePeriod(String newPeriod) {
    emit(DashboardPeriodUpdated(newPeriod));
  }
}
