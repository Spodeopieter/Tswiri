import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sunbird/views/settings/backup/classes/backup.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GoogleDriveBackup extends Backup {
  GoogleDriveBackup({
    required super.progressNotifier,
    required this.driveApi,
  });

  drive.DriveApi driveApi;

  ///Returns the backup folder ID of this app.
  Future<String?> getFolderID() async {
    const mimeType = "application/vnd.google-apps.folder";
    String folderName = "sunbird_backup";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );

      final files = found.files;

      if (files == null) {
        log("Sign-in first Error");
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      drive.File folder = drive.File();
      folder.name = folderName;
      folder.mimeType = mimeType;

      final folderCreation = await driveApi.files.create(folder);

      return folderCreation.id;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  ///Returns the latest backup file.
  Future<drive.File?> getLatestBackup() async {
    log('getting latest');
    String? folderId = await getFolderID();

    drive.FileList fileList = await driveApi.files.list(
        spaces: 'drive',
        q: "'$folderId' in parents",
        orderBy: "createdTime",
        $fields: "*");

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files?.last;
    } else {
      return null;
    }
  }

  Future<bool> uploadFile(File file) async {
    String? folderId = await getFolderID();

    if (folderId == null) {
      return false;
    } else {
      drive.File fileToUpload = drive.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = p.basename(file.absolute.path);
      var response = await driveApi.files.create(
        fileToUpload,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );
      return true;
    }
  }

  Future<File?> downloadFile(drive.File file) async {
    drive.Media selectedFile = await driveApi.files.get(file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    File downloadedFile =
        File('${(await getTemporaryDirectory()).path}/download/${file.name}');

    if (!downloadedFile.existsSync()) {
      downloadedFile.createSync(recursive: true);
    }

    List<int> dataStore = [];

    var completer = Completer<File?>();

    selectedFile.stream.listen((data) {
      log("DataReceived: ${data.length}");
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () {
      log("Task Done");
      downloadedFile.writeAsBytes(dataStore);
      log("File saved at ${downloadedFile.path}");
      completer.complete(downloadedFile);
    }, onError: (error) {
      log("Some Error");
      completer.complete(null);
    });

    return completer.future;
  }
}

final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[
    'https://www.googleapis.com/auth/drive.file',
  ],
);

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
