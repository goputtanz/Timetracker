import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'local_database.dart';

class BackupRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Add timeout to sign in
      _currentUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Sign in timed out');
        },
      );

      if (_currentUser != null) {
        // Add timeout to getting authenticated client
        final httpClient = await _googleSignIn.authenticatedClient().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Authentication timed out');
          },
        );

        if (httpClient != null) {
          _driveApi = drive.DriveApi(httpClient);
        }
      }
      return _currentUser;
    } catch (e) {
      debugPrint('Sign in failed: $e');
      // Ensure we clean up if something failed halfway
      _currentUser = null;
      _driveApi = null;
      rethrow; // Rethrow to let ViewModel handle it
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _driveApi = null;
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  Future<bool> uploadBackup() async {
    if (_driveApi == null) return false;

    try {
      final dbPath = await LocalDatabase.instance.getDbPath();
      final file = File(dbPath);
      if (!file.existsSync()) return false;

      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = drive.File()
        ..name = 'staytics_backup.db'
        ..parents = ['appDataFolder'];

      // Check if file exists to update or create new
      final fileList = await _driveApi!.files.list(
        q: "name = 'staytics_backup.db' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        await _driveApi!.files.update(driveFile, fileId, uploadMedia: media);
      } else {
        await _driveApi!.files.create(driveFile, uploadMedia: media);
      }
      return true;
    } catch (e) {
      debugPrint('Upload failed: \$e');
      return false;
    }
  }

  Future<bool> restoreBackup() async {
    if (_driveApi == null) return false;

    try {
      final fileList = await _driveApi!.files.list(
        q: "name = 'staytics_backup.db' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final fileId = fileList.files!.first.id!;
      final drive.Media media =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final dbPath = await LocalDatabase.instance.getDbPath();
      final file = File(dbPath);

      // Close DB before overwriting
      await LocalDatabase.instance.close();

      final sink = file.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return true;
    } catch (e) {
      debugPrint('Restore failed: \$e');
      return false;
    }
  }
}