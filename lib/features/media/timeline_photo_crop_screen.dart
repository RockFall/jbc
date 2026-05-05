import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

/// Enquadramento 4:3 (alinhado aos cartões da timeline), zoom/pan com [interactive].
class TimelinePhotoCropScreen extends StatefulWidget {
  const TimelinePhotoCropScreen({
    super.key,
    required this.imageBytes,
    this.progressLabel,
  });

  final Uint8List imageBytes;
  final String? progressLabel;

  @override
  State<TimelinePhotoCropScreen> createState() => _TimelinePhotoCropScreenState();
}

class _TimelinePhotoCropScreenState extends State<TimelinePhotoCropScreen> {
  final _controller = CropController();
  var _busy = false;

  void _onCropped(CropResult result) {
    if (!mounted) return;
    if (result is CropSuccess) {
      Navigator.of(context).pop<Uint8List>(result.croppedImage);
      return;
    }
    if (result is CropFailure) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível cortar: ${result.cause}')),
      );
    }
  }

  void _resetFraming() {
    _controller.image = widget.imageBytes;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.progressLabel;
    return Scaffold(
      appBar: AppBar(
        title: Text(label == null ? 'Enquadrar foto' : 'Enquadrar ($label)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Ignorar esta foto',
          onPressed: _busy ? null : () => Navigator.of(context).pop<Uint8List?>(null),
        ),
        actions: [
          Tooltip(
            message: 'Volta ao enquadramento inicial sobre a foto',
            child: TextButton(
              onPressed: _busy ? null : _resetFraming,
              child: const Text('Repor enquadramento'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              aspectRatio: 4 / 3,
              interactive: true,
              initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                size: 0.9,
                aspectRatio: 4 / 3,
              ),
              onCropped: _onCropped,
              progressIndicator: const Center(child: CircularProgressIndicator()),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'Adiciona a foto original deste passo, sem recorte',
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop<Uint8List>(widget.imageBytes),
                        child: const Text('Usar sem cortar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: 'Confirma o recorte 4:3 atual',
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() => _busy = true);
                                _controller.crop();
                              },
                        child: const Text('Confirmar enquadramento'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
