import "dart:io";
import "dart:typed_data";

import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;

class ConvertImgPdf {
  Future<Uint8List> convert(List<File> imageFiles) async {
    if (imageFiles.isEmpty) {
      throw ArgumentError("No images were provided.");
    }

    final pdf = pw.Document();

    for (final file in imageFiles) {
      final image = pw.MemoryImage(await file.readAsBytes());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          )
        )
      );
    }

    return pdf.save();
  }
}