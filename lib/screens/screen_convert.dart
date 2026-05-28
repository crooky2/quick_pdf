import "dart:io";
import "dart:async";

import 'package:flutter/material.dart';

import "../services/service_receive.dart";
import "../services/service_pdf.dart";


class ScreenConvert extends StatefulWidget {
  const ScreenConvert({super.key});

  @override
  State<ScreenConvert> createState() => _ScreenConvertState();
}

class _ScreenConvertState extends State<ScreenConvert> {
  final ServiceReceive _receive = ServiceReceive();
  final ServicePdf _pdf = ServicePdf();

  StreamSubscription<List<File>>? _imageSubscription;

  File? _pdfFile;
  bool _busy = false;
  String _status = "Share an image to QuickPDF";

  @override
  void initState() {
    super.initState();

    _imageSubscription = _receive.watchImages().listen(_convertImages);

    _loadInitialImages();
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialImages() async {
    final images = await _receive.getInitialImages();
    if (images.isEmpty) return;
  }

  Future<void> _convertImages(List<File> images) async {
    if (images.isEmpty) return;

    setState(() {
      _busy = true;
      _status = "Converting ${images.length} image(s)...";
    });

    try {
      final pdfFile = await _pdf.createFromImages(images);

      setState(() {
        _pdfFile = pdfFile;
        _status = "Finished.";
      });
    } catch (_) {
      setState(() {
        _status = "Failed.";
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _savePdf() async {
    final file = _pdfFile;
    if (file == null) return;

    await _pdf.save(file);
    _showMessage("Saved.");
  }

  Future<void> _sharePdf() async {
    final file = _pdfFile;
    if (file == null) return;

    await _pdf.share(file);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfFile = _pdfFile;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _busy
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pdfFile == null 
                        ? Icons.image_outlined 
                        : Icons.picture_as_pdf,
                    size: 72
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  if (pdfFile != null) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _savePdf,
                          icon: const Icon(Icons.save_alt),
                          label: const Text("Save")
                        ),
                        FilledButton.icon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share),
                          label: const Text("Share")
                        ),
                      ]
                    )
                  ]
                ]
              )
        )
      )
    );
  }
}