import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'stay_image.dart';
import 'location_photo_data.dart';

final stayPhotos = locationPhotos;

// Lead with the brightest, tidiest room photo for the destination. Keep the
// remaining photos available in the carousel and gallery.
const _preferredCover = <String, int>{
  'pine': 1,
  'hanoi': 2,
  'ninhbinh': 1,
  'halong': 1,
  'hue': 2,
  'nhatrang': 2,
};

List<StayImage> photosFor(String id) {
  var photos = stayPhotos[id];
  if (photos == null || photos.isEmpty) {
    final cityKey = stayPhotos.keys
        .where((key) => id.startsWith('$key-'))
        .firstOrNull;
    photos = cityKey == null ? stayPhotos['sea'] : stayPhotos[cityKey];
  }
  if (photos == null || photos.isEmpty) return const <StayImage>[];
  final coverIndex = _preferredCover[id] ?? 0;
  if (coverIndex == 0 || coverIndex >= photos.length) return photos;
  return [
    photos[coverIndex],
    ...photos.take(coverIndex),
    ...photos.skip(coverIndex + 1),
  ];
}

class StayGallery extends StatefulWidget {
  const StayGallery(
    this.id, {
    super.key,
    this.fullscreen = false,
    this.initial = 0,
  });
  final String id;
  final bool fullscreen;
  final int initial;
  @override
  State<StayGallery> createState() => _StayGalleryState();
}

class _StayGalleryState extends State<StayGallery> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final photos = photosFor(widget.id);
    final current = photos[_index];
    final viewer = Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 20),
            child: PageView.builder(
              controller: _pages,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final photo = Image.asset(
                  photos[i].asset,
                  fit: widget.fullscreen ? BoxFit.contain : BoxFit.cover,
                  width: double.infinity,
                  semanticLabel: photos[i].caption,
                );
                return widget.fullscreen
                    ? InteractiveViewer(child: photo)
                    : GestureDetector(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => Dialog.fullscreen(
                            child: SafeArea(
                              child: StayGallery(
                                widget.id,
                                fullscreen: true,
                                initial: i,
                              ),
                            ),
                          ),
                        ),
                        child: photo,
                      );
              },
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton.filledTonal(
              tooltip: 'Ảnh trước',
              onPressed: _index > 0 ? () => _select(_index - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton.filledTonal(
              tooltip: 'Ảnh tiếp theo',
              onPressed: _index < photos.length - 1
                  ? () => _select(_index + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '${_index + 1} / ${photos.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
    return Column(
      mainAxisSize: widget.fullscreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.fullscreen)
          Row(
            children: [
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Album ảnh tham khảo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Đóng ảnh',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        if (widget.fullscreen)
          Expanded(child: viewer)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return SizedBox(height: 260, child: viewer);
              }
              return SizedBox(
                height: 380,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: viewer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          for (var i = 1; i < 3; i++) ...[
                            if (i > 1) const SizedBox(height: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _select(i),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        photos[i].asset,
                                        fit: BoxFit.cover,
                                        semanticLabel:
                                            'Xem ${photos[i].caption}',
                                      ),
                                      if (i == 2)
                                        Positioned(
                                          right: 10,
                                          bottom: 10,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(7),
                                              child: Text(
                                                'Xem ${photos.length} ảnh',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
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
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, i) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Semantics(
              selected: _index == i,
              button: true,
              label: 'Xem ảnh ${i + 1}: ${photos[i].caption}',
              child: InkWell(
                onTap: () => _select(i),
                child: Container(
                  width: 88,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _index == i ? brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      photos[i].asset,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${current.caption} • Ảnh chụp tham khảo',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
        if (widget.fullscreen)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Ảnh: ${current.author}', textAlign: TextAlign.center),
                SelectableText(
                  current.source,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ảnh từ nhiều địa điểm, dùng minh họa cho dữ liệu demo; không phải ảnh xác thực của homestay này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
