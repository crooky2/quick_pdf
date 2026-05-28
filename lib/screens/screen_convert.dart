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

  final List<PdfPageImage> _pages = [];
  final Set<String> _selectedPageIds = {};

  bool _busy = false;
  String _status = "Share images to QuickPDF";

  @override
  void initState() {
    super.initState();

    _imageSubscription = _receive.watchImages().listen(_loadPages);
    _loadInitialImages();
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialImages() async {
    final images = await _receive.getInitialImages();
    _loadPages(images);
  }

  void _loadPages(List<File> images) {
    if (images.isEmpty) return;

    setState(() {
      _pages
        ..clear()
        ..addAll(
          images.map(
            (file) => PdfPageImage(
              id: "${file.path}-${DateTime.now().microsecondsSinceEpoch}",
              file: file,
            ),
          ),
        );

      _selectedPageIds
        ..clear()
        ..addAll(_pages.map((page) => page.id));

      _status = _pageStatus;
    });
  }

  List<File> get _selectedPages {
    return _pages
        .where((page) => _selectedPageIds.contains(page.id))
        .map((page) => page.file)
        .toList();
  }

  String get _pageStatus =>
      _pages.length == 1 ? "1 page" : "${_pages.length} pages";

  Future<void> _savePdf() async {
    final pages = _selectedPages;
    if (pages.isEmpty) return;

    setState(() {
      _busy = true;
      _status = "Saving...";
    });

    try {
      final pdfFile = await _pdf.createFromImages(pages);
      await _pdf.save(pdfFile);
      _showMessage("Saved.");
    } catch (e) {
      _showMessage("Failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = _pageStatus;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    final pages = _selectedPages;
    if (pages.isEmpty) return;

    setState(() {
      _busy = true;
      _status = "Sharing...";
    });

    try {
      final pdfFile = await _pdf.createFromImages(pages);
      await _pdf.share(pdfFile);
    } catch (e) {
      _showMessage("Failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = _pageStatus;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? Center(
                  child: Column(
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
                  ),
                )
              : Column(
                  children: [
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _pages.length,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            type: MaterialType.transparency,
                            child: child,
                          );
                        },
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final page = _pages.removeAt(oldIndex);
                            _pages.insert(newIndex, page);
                          });
                        },
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          final selected = _selectedPageIds.contains(page.id);
                          final pageLabel =
                              "Page ${index + 1} of ${_pages.length}";
                          final colorScheme = Theme.of(context).colorScheme;

                          return Padding(
                            key: ValueKey(page.id),
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selectedPageIds.remove(page.id);
                                      } else {
                                        _selectedPageIds.add(page.id);
                                      }
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? colorScheme.primary
                                                : colorScheme.outlineVariant,
                                            width: selected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 1 / 1.414,
                                          child: Image.file(
                                            page.file,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 160,
                                          ),
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? colorScheme.primary
                                                : colorScheme.surface
                                                      .withValues(alpha: 0.92),
                                            border: Border.all(
                                              color: selected
                                                  ? colorScheme.primary
                                                  : colorScheme.outline,
                                            ),
                                          ),
                                          child: selected
                                              ? Icon(
                                                  Icons.check,
                                                  size: 20,
                                                  color: colorScheme.onPrimary,
                                                )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 22,
                                        child: Center(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.48,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              child: Text(
                                                pageLabel,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _selectedPages.isEmpty ? null : _savePdf,
                          icon: const Icon(Icons.save_alt),
                          label: const Text("Save"),
                        ),
                        FilledButton.icon(
                          onPressed: _selectedPages.isEmpty ? null : _sharePdf,
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
