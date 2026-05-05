import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TimelinePhotoLightbox extends StatefulWidget {
  const TimelinePhotoLightbox({
    super.key,
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<TimelinePhotoLightbox> createState() => _TimelinePhotoLightboxState();
}

class _TimelinePhotoLightboxState extends State<TimelinePhotoLightbox> {
  late final PageController _pageController;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text('${_page + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Semantics(
                label: 'Foto ${i + 1} de ${widget.urls.length} em ecrã completo',
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  fadeInDuration: Duration.zero,
                  placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white54),
                  errorWidget: (context, url, error) => Icon(Icons.broken_image_outlined, size: 64, color: scheme.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
