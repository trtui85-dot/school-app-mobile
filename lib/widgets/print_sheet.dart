import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme.dart';
import 'toast.dart';

/// A4 aspect ratio sheet: width 360 → height 509 (595.28/841.89 ≈ 0.7067).
const double printPageWidth = 360;
const double printPageHeight = 509;

/// Full-screen print preview with "تحميل كصورة" and "طباعة" actions.
/// [pages] are rendered as stacked A4-ratio sheets; printing builds one
/// A4 PDF page per sheet (no stretching, no single elongated page).
class PrintSheetScreen extends StatefulWidget {
  final String title;
  final List<Widget> pages;
  final String? fileName;
  const PrintSheetScreen({
    super.key,
    required this.title,
    required this.pages,
    this.fileName,
  });
  @override
  State<PrintSheetScreen> createState() => _PrintSheetScreenState();
}

class _PrintSheetScreenState extends State<PrintSheetScreen> {
  final List<GlobalKey> _keys = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(widget.pages.length, (_) => GlobalKey()));
  }

  Future<List<Uint8List?>> _captureAll() async {
    // Capture at the exact A4 pixel ratio so pages never stretch or elongate.
    final pixelRatio = PdfPageFormat.a4.width / printPageWidth;
    final out = <Uint8List?>[];
    for (final key in _keys) {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) continue;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      out.add(data?.buffer.asUint8List());
    }
    return out;
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _captureAll();
      if (bytes.isEmpty) return;
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      for (var i = 0; i < bytes.length; i++) {
        final b = bytes[i];
        if (b == null) continue;
        final suffix = bytes.length > 1 ? '-${i + 1}' : '';
        await Gal.putImageBytes(b, name: '${widget.fileName ?? 'sheet'}$suffix');
      }
      if (mounted) showToast(context, bytes.length > 1 ? 'تم حفظ الصور في المعرض' : 'تم حفظ الصورة في المعرض');
    } catch (_) {
      if (mounted) showToast(context, 'تعذر حفظ الصور', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print() async {
    try {
      final bytes = await _captureAll();
      if (bytes.isEmpty) return;
      final doc = pw.Document();
      for (final b in bytes) {
        if (b == null) continue;
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            orientation: pw.PageOrientation.portrait,
            build: (_) => pw.Center(
              child: pw.Image(
                pw.MemoryImage(b),
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      }
      await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: widget.fileName ?? 'sheet');
    } catch (_) {
      if (mounted) showToast(context, 'تعذرت الطباعة', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title, style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.zinc700),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _download,
            icon: _saving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download, size: 18),
            label: Text('صورة', style: ar(13, FontWeight.w600, AppColors.accent)),
          ),
          TextButton.icon(
            onPressed: _print,
            icon: const Icon(Icons.print, size: 18),
            label: Text('طباعة', style: ar(13, FontWeight.w600, AppColors.accent)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < widget.pages.length; i++) ...[
              RepaintBoundary(
                key: _keys[i],
                child: Center(child: widget.pages[i]),
              ),
              if (i < widget.pages.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// White A4-ratio page container used by print screens.
Widget printPage({required Widget child, bool addShadow = true}) {
  return Container(
    width: printPageWidth,
    height: printPageHeight,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: addShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : const [],
    ),
    child: child,
  );
}