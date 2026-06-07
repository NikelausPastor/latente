import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class FileImportService {
  Future<String?> pickTechnicalTextFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'txt'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const FileImportException(
        'Il file selezionato non puo essere letto su questo dispositivo.',
      );
    }

    return utf8.decode(bytes, allowMalformed: true);
  }
}

class FileImportException implements Exception {
  const FileImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
