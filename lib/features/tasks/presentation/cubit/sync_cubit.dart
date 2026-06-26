import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/usecases/sync_tasks_usecase.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final NetworkInfo networkInfo;
  final SyncTasksUseCase syncTasksUseCase;

  SyncCubit({
    required this.networkInfo,
    required this.syncTasksUseCase,
  }) : super(SyncInitial());

  Future<void> syncTasks() async {
    emit(SyncInProgress());
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await syncTasksUseCase();
        emit(SyncSuccess());
      } else {
        emit(const SyncFailure('Cannot sync offline. No internet connection.'));
      }
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }
}
