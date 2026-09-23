import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

class ImageUpload extends StatefulWidget {
  final String label;
  final ValueChanged<String?>? onChange;
  const ImageUpload({super.key, this.label = 'صورة إثبات الدفع', this.onChange});

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  String? _base64;
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 100);
      if (picked == null) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      final raw = await picked.readAsBytes();
      final encoded = _compress(raw);
      setState(() {
        _base64 = encoded;
        _busy = false;
      });
      widget.onChange?.call(encoded);
    } catch (_) {
      setState(() {
        _busy = false;
        _error = tr('تعذر ضغط الصورة');
      });
    }
  }

  String _compress(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw Exception('decode');
    }
    final maxDim = decoded.width > decoded.height ? decoded.width : decoded.height;
    img.Image out = decoded;
    if (maxDim > 900) {
      if (decoded.width >= decoded.height) {
        out = img.copyResize(decoded, width: 900);
      } else {
        out = img.copyResize(decoded, height: 900);
      }
    }
    final jpg = img.encodeJpg(out, quality: 70);
    return base64Encode(jpg);
  }

  void _sheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
              title: Text(tr('اختيار من المعرض'), style: ar(14, FontWeight.w500, AppColors.foreground)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accent),
              title: Text(tr('التقاط صورة'), style: ar(14, FontWeight.w500, AppColors.foreground)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(widget.label), style: ar(14, FontWeight.w500, AppColors.zinc700)),
        const SizedBox(height: 6),
        if (_base64 != null)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 176,
                decoration: BoxDecoration(
                  color: AppColors.zinc50,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.zinc200),
                ),
                child: Image.memory(
                  base64Decode(_base64!),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _base64 = null);
                    widget.onChange?.call(null);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _busy ? null : _sheet,
            child: Container(
              width: double.infinity,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.zinc300, width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.zinc500),
                  const SizedBox(height: 8),
                  Text(_busy ? tr('جارٍ الضغط...') : tr('اضغط لرفع الصورة'), style: ar(14, FontWeight.w500, AppColors.zinc500)),
                  const SizedBox(height: 4),
                  Text(tr('تُضغط الصورة تلقائيًا قبل الرفع'), style: ar(12, FontWeight.w400, AppColors.zinc400)),
                ],
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: ar(12, FontWeight.w400, AppColors.bad)),
          ),
      ],
    );
  }
}
