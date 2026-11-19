import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/utils.dart';

/// Rectangular rotating banners shown under the top header.
/// Fetches active ads from /api/public/ads and auto-advances between them.
class AdsCarousel extends StatefulWidget {
  final double height;
  const AdsCarousel({super.key, this.height = 150});

  @override
  State<AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<AdsCarousel> {
  List<Map<String, dynamic>>? _ads;
  int _index = 0;
  PageController? _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/public/ads', useCache: false);
      if (!mounted) return;
      final ads = asMapList(d['ads']);
      setState(() => _ads = ads);
      if (ads.length > 1) {
        _controller = PageController();
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 4), (_) => _next());
      }
    } on ApiException {
      if (mounted) setState(() => _ads = []);
    }
  }

  void _next() {
    final ads = _ads;
    if (ads == null || ads.length < 2) return;
    final controller = _controller;
    if (controller == null) return;
    final next = (_index + 1) % ads.length;
    controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = _ads;
    if (ads == null || ads.isEmpty) return const SizedBox.shrink();
    if (ads.length == 1) return _frame(Image.memory(base64DecodeSafe(asStr(ads.first['image'])), fit: BoxFit.cover));

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: ads.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _frame(
                Image.memory(base64DecodeSafe(asStr(ads[i]['image'])), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < ads.length; i++)
                    Container(
                      width: i == _index ? 14 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frame(Widget child) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: child,
    );
  }
}
