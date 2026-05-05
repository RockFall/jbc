import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media/timeline_photo_limits.dart';
import 'timeline_photo_crop_screen.dart';

/// Abre a galeria com multi-seleção, pré-visualização com remoção, depois crop por foto.
/// Devolve quantas fotos foram adicionadas com sucesso.
Future<int> pickCropAndAppendTimelinePhotos({
  required BuildContext context,
  required int currentSlotCount,
  required void Function(Uint8List bytes, XFile refFile) onAppend,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final remainingSlots = kMaxTimelinePhotosPerMemory - currentSlotCount;
  if (remainingSlots <= 0) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Limite de fotos para esta memória atingido.')),
    );
    return 0;
  }

  final picker = ImagePicker();
  late final List<XFile> picked;
  try {
    picked = await picker.pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Galeria: $e')),
    );
    return 0;
  }

  if (picked.isEmpty) return 0;

  var files = picked.take(remainingSlots).take(kMaxGalleryPickBatch).toList();

  if (!context.mounted) return 0;
  final reviewed = await showModalBottomSheet<List<XFile>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _MultiPhotoReviewSheet(initial: files),
  );

  if (reviewed == null || reviewed.isEmpty) return 0;
  files = reviewed;

  var added = 0;
  var index = 0;
  for (final f in files) {
    index++;
    Uint8List raw;
    try {
      raw = await f.readAsBytes();
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Não foi possível ler uma foto ($index): $e')),
      );
      continue;
    }
    if (!context.mounted) return added;

    final cropped = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        builder: (_) => TimelinePhotoCropScreen(
          imageBytes: raw,
          progressLabel: '$index/${files.length}',
        ),
      ),
    );

    if (!context.mounted) return added;
    if (cropped == null) continue;

    final ref = XFile.fromData(
      cropped,
      name: 'timeline_${DateTime.now().millisecondsSinceEpoch}_$index.jpg',
      mimeType: 'image/jpeg',
    );
    onAppend(cropped, ref);
    added++;
  }

  if (added < files.length && context.mounted) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'Nenhuma foto foi adicionada.'
              : 'Adicionadas $added de ${files.length} fotos.',
        ),
      ),
    );
  }

  return added;
}

/// Uma foto da câmera com o mesmo fluxo de crop.
Future<int> pickCropCameraTimelinePhoto({
  required BuildContext context,
  required int currentSlotCount,
  required void Function(Uint8List bytes, XFile refFile) onAppend,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (currentSlotCount >= kMaxTimelinePhotosPerMemory) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Limite de fotos para esta memória atingido.')),
    );
    return 0;
  }

  final picker = ImagePicker();
  XFile? shot;
  try {
    shot = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text('Câmera: $e')));
    return 0;
  }
  if (shot == null) return 0;

  Uint8List raw;
  try {
    raw = await shot.readAsBytes();
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text('Não foi possível ler a foto: $e')));
    return 0;
  }

  if (!context.mounted) return 0;
  final cropped = await Navigator.of(context).push<Uint8List?>(
    MaterialPageRoute(
      builder: (_) => TimelinePhotoCropScreen(imageBytes: raw),
    ),
  );

  if (!context.mounted || cropped == null) return 0;

  final ref = XFile.fromData(
    cropped,
    name: 'timeline_${DateTime.now().millisecondsSinceEpoch}.jpg',
    mimeType: 'image/jpeg',
  );
  onAppend(cropped, ref);
  return 1;
}

class _MultiPhotoReviewSheet extends StatefulWidget {
  const _MultiPhotoReviewSheet({required this.initial});

  final List<XFile> initial;

  @override
  State<_MultiPhotoReviewSheet> createState() => _MultiPhotoReviewSheetState();
}

class _MultiPhotoReviewSheetState extends State<_MultiPhotoReviewSheet> {
  late List<XFile> _files;

  @override
  void initState() {
    super.initState();
    _files = List<XFile>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_files.length} foto(s) selecionada(s)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Pode remover antes de enquadrar. Máx. $kMaxGalleryPickBatch por vez.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _files.length,
              separatorBuilder: (_, unusedIndex) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final f = _files[i];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: _ReviewThumb(file: f),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          tooltip: 'Remover desta lista',
                          onPressed: () {
                            setState(() => _files.removeAt(i));
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _files.isEmpty
                ? null
                : () => Navigator.of(context).pop<List<XFile>>(List<XFile>.from(_files)),
            child: const Text('Continuar para enquadrar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop<List<XFile>?>(null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _ReviewThumb extends StatelessWidget {
  const _ReviewThumb({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Icon(Icons.broken_image_outlined);
        }
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }
}
