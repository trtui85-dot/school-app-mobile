import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/image_upload.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});
  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  List<Map<String, dynamic>>? _ads;
  final _titleCtrl = TextEditingController();
  String? _image;
  bool _submitting = false;
  String _formError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _ads = null);
    try {
      final d = await ApiClient.instance.get('/api/admin/ads');
      if (!mounted) return;
      setState(() => _ads = asMapList(d['ads']));
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.message, type: ToastType.error);
      setState(() => _ads = []);
    }
  }

  Future<void> _add() async {
    if (_image == null) {
      return setState(() => _formError = 'اختر صورة الإعلان أولًا');
    }
    setState(() {
      _formError = '';
      _submitting = true;
    });
    try {
      await ApiClient.instance.post('/api/admin/ads', body: {
        'image': _image,
        'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      });
      if (!mounted) return;
      showToast(context, 'تمت إضافة الإعلان');
      _titleCtrl.clear();
      setState(() => _image = null);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> ad) async {
    final okDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text('حذف هذا الإعلان؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (okDelete != true) return;
    try {
      await ApiClient.instance.delete('/api/admin/ads?id=${asInt(ad['id'])}');
      if (mounted) showToast(context, 'تم حذف الإعلان');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('المساحة الإعلانية', style: AppText.h1),
          const SizedBox(height: 4),
          Text(
            'هذه الصور تظهر تلقائيًا في أعلى واجهة الوكلاء وتتبادل بينها تلقائيًا.',
            style: ar(12, FontWeight.w400, AppColors.zinc500),
          ),
          const SizedBox(height: 16),
          AppCard(child: _addForm()),
          const SizedBox(height: 16),
          if (_ads == null)
            const AppSpinner()
          else if (_ads!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد إعلانات بعد — أضف صورة أعلاه'))
          else
            ..._ads!.map((ad) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _adCard(ad),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _addForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إضافة إعلان جديد', style: AppText.h2),
        const SizedBox(height: 12),
        AppInput(label: 'وصف قصير (اختياري)', controller: _titleCtrl),
        const SizedBox(height: 12),
        ImageUpload(label: 'صورة الإعلان', onChange: (v) => _image = v),
        if (_formError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_formError, style: ar(13, FontWeight.w400, AppColors.bad)),
        ],
        const SizedBox(height: 12),
        AppButton(
          text: 'إضافة الإعلان',
          expand: true,
          loading: _submitting,
          onPressed: _add,
        ),
      ],
    );
  }

  Widget _adCard(Map<String, dynamic> ad) {
    final title = asStrOrNull(ad['title']);
    final image = asStr(ad['image']);
    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            child: Container(
              width: double.infinity,
              height: 140,
              color: AppColors.zinc50,
              child: image.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined, color: AppColors.zinc300)
                  : Image.memory(base64DecodeSafe(image), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(title ?? 'إعلان',
                      overflow: TextOverflow.ellipsis,
                      style: ar(14, FontWeight.w600, AppColors.foreground)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.bad),
                  tooltip: 'حذف',
                  onPressed: () => _delete(ad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}