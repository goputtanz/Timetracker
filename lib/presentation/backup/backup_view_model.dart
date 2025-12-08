import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/backup_repository.dart';

class BackupSetupViewModel extends Notifier<BackupSetupState> {
  late final BackupRepository _repository;

  @override
  BackupSetupState build() {
    _repository = BackupRepository();
    return const BackupSetupState();
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await _repository.signIn();
      state = state.copyWith(
        isLoading: false,
        account: account,
        isSignedIn: account != null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSignedIn: false,
        errorMessage: 'Failed to sign in: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const BackupSetupState();
  }

  Future<bool> restoreBackup() async {
    state = state.copyWith(isRestoring: true);
    final success = await _repository.restoreBackup();
    state = state.copyWith(isRestoring: false);
    return success;
  }
}

final backupSetupProvider =
    NotifierProvider<BackupSetupViewModel, BackupSetupState>(() {
      return BackupSetupViewModel();
    });

@immutable
class BackupSetupState {
  final bool isLoading;
  final bool isRestoring;
  final bool isSignedIn;
  final GoogleSignInAccount? account;
  final String? errorMessage;

  const BackupSetupState({
    this.isLoading = false,
    this.isRestoring = false,
    this.isSignedIn = false,
    this.account,
    this.errorMessage,
  });

  BackupSetupState copyWith({
    bool? isLoading,
    bool? isRestoring,
    bool? isSignedIn,
    GoogleSignInAccount? account,
    String? errorMessage,
  }) {
    return BackupSetupState(
      isLoading: isLoading ?? this.isLoading,
      isRestoring: isRestoring ?? this.isRestoring,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      account: account ?? this.account,
      errorMessage:
          errorMessage, // Allow clearing by passing null if needed, but here we usually just set it
    );
  }
}
