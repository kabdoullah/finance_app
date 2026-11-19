import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Fichier produit par l'application (sauvegarde, export), enregistré à
/// l'emplacement choisi (sélecteur d'Android, Drive compris) ou partagé.
class FileOutput {
  const FileOutput();

  /// `false` si l'utilisateur a annulé.
  Future<bool> save(String fileName, Uint8List bytes, String mimeType) async =>
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      ) !=
      null;

  /// `false` si l'utilisateur a fermé le menu de partage.
  Future<bool> share(String fileName, Uint8List bytes, String mimeType) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}

final fileOutputProvider = Provider<FileOutput>((ref) => const FileOutput());
