import "dart:io";

import "package:flutter/services.dart";
import "package:file_saver/file_saver.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:share_plus/share_plus.dart";

import "../convert/convert_img_pdf.dart";

class PdfPageImage {
  PdfPageImage({required this.id, required this.file});

  final String id;
  final File file;
}

class ServicePdf {
  final ConvertImgPdf _converter = ConvertImgPdf();

  Future<File> createFromImages(List<File> images) async {
    final bytes = await _converter.convert(images);
    final directory = await getTemporaryDirectory();

    final file = File(p.join(directory.path, "quick_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf"));

    await file.writeAsBytes(bytes, flush:true);
    return file;
  }

  Future<void> copyPath(File pdfFile) {
    return Clipboard.setData(ClipboardData(text: pdfFile.path));
  }

  Future<void> save(File pdfFile) {
    return FileSaver.instance.saveFile(
      name: p.basenameWithoutExtension(pdfFile.path),
      file: pdfFile,
      fileExtension: "pdf",
      mimeType: MimeType.pdf
    );
  }

  Future<void> share(File pdfFile) async {
    await SharePlus.instance.share(
      ShareParams(
        title: "Quick PDF",
        files: [XFile(pdfFile.path, mimeType: "application/pdf")]
      )
    );
  }
}