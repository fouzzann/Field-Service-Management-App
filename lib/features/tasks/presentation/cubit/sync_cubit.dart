import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/usecases/sync_tasks_usecase.dart';
import 'sync_state.dart';

// This Cubit manages the state of the offline-to-cloud synchronization process.
// It tells the UI if a sync is currently running, finished successfully, or failed.
class SyncCubit extends Cubit<SyncState> {
  final NetworkInfo networkInfo;
  final SyncTasksUseCase syncTasksUseCase;

  SyncCubit({
    required this.networkInfo,
    required this.syncTasksUseCase,
  }) : super(SyncInitial()); // Starts in the "Initial" idle state.

  // Manually triggers the sync of offline tasks.
  Future<void> syncTasks() async {
    emit(SyncInProgress()); // 1. Tell UI that sync is in progress (show progress bar/spinner).
    
    try {
      // 2. Check if the device has working internet.
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        // 3. Upload offline data to Firestore.
        await syncTasksUseCase();
        emit(SyncSuccess()); // Sync finished successfully!
      } else {
        // 4. Fail if offline.
        emit(const SyncFailure('Cannot sync offline. No internet connection.'));
      }
    } catch (e) {
      // Emit failure if any unexpected error happens.
      emit(SyncFailure(e.toString()));
    }
  }
}
