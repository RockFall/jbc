import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/hangout.dart';
import '../../data/models/timeline_event.dart';
import 'hangouts_format.dart';

class _ImageSlot {
  _ImageSlot.local(this.bytes, this.file);

  final Uint8List bytes;
  final XFile file;
}

class HangoutMemoryScreen extends ConsumerStatefulWidget {
  const HangoutMemoryScreen({super.key, required this.hangout});

  final Hangout hangout;

  @override
  ConsumerState<HangoutMemoryScreen> createState() => _HangoutMemoryScreenState();
}

class _HangoutMemoryScreenState extends ConsumerState<HangoutMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _occurredDate;
  final List<_ImageSlot> _slots = [];
  int _primaryIndex = 0;
  bool _saving = false;

  static String _descFromHangout(Hangout h) {
    final parts = <String>[];
    final d = h.description?.trim();
    if (d != null && d.isNotEmpty) parts.add(d);
    final n = h.notes?.trim();
    if (n != null && n.isNotEmpty) parts.add(n);
    return parts.join('\n\n');
  }

  @override
  void initState() {
    super.initState();
    final h = widget.hangout;
    _titleController = TextEditingController(text: h.title);
    _descriptionController = TextEditingController(text: _descFromHangout(h));
    final local = h.date.toLocal();
    _occurredDate = DateTime(local.year, local.month, local.day);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _occurredAtForSave() {
    final d = _occurredDate;
    return DateTime(d.year, d.month, d.day, 12).toUtc();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _slots.add(_ImageSlot.local(bytes, file));
        if (_slots.length == 1) _primaryIndex = 0;
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeAt(int i) {
    setState(() {
      _slots.removeAt(i);
      if (_slots.isEmpty) {
        _primaryIndex = 0;
      } else if (_primaryIndex >= _slots.length) {
        _primaryIndex = _slots.length - 1;
      }
    });
  }

  String _extFor(XFile file) {
    var ext = p.extension(file.path).replaceFirst('.', '');
    if (ext.isEmpty) ext = 'jpg';
    return ext;
  }

  List<TimelineImageInput> _inputsForSave() {
    return [
      for (final s in _slots)
        TimelineImageInput.upload(s.bytes, _extFor(s.file)),
    ];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    final h = widget.hangout;
    if (h.status != HangoutStatus.happened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O rolê precisa estar como “aconteceu”.')),
      );
      return;
    }
    if (h.timelineEventId != null && h.timelineEventId!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este rolê já tem memória na timeline.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final inputs = _inputsForSave();
      final pIdx = _slots.isEmpty ? 0 : _primaryIndex.clamp(0, _slots.length - 1);

      await ref.read(repositoryProvider).createTimelineFromHangout(
            hangout: h,
            profile: profile,
            occurredAt: _occurredAtForSave(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            images: inputs,
            primaryImageIndex: pIdx,
          );
      ref.invalidate(timelineEventsProvider);
      ref.invalidate(hangoutsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memória registrada na timeline.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _thumb(BuildContext context, _ImageSlot s, int index) {
    final isPrimary = _slots.isNotEmpty && index == _primaryIndex;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 96,
            height: 96,
            child: Image.memory(s.bytes, fit: BoxFit.cover),
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
              onPressed: _saving ? null : () => _removeAt(index),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Material(
            color: isPrimary
                ? Theme.of(context).colorScheme.primary
                : Colors.black45,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _saving ? null : () => setState(() => _primaryIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrimary ? Icons.star : Icons.star_outline,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPrimary ? 'Principal' : 'Capa',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hangout;
    final blocked = h.timelineEventId != null && h.timelineEventId!.isNotEmpty;

    if (blocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memória do rolê')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Este rolê já foi registrado na timeline.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memória do rolê'),
        actions: [
          TextButton(
            style: AppTheme.appBarActionTextButtonStyle,
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.appBarOnBrandForeground,
                    ),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            Text(
              'Ajuste o texto e as fotos antes de salvar. O vínculo com o rolê é automático.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quando aconteceu'),
              subtitle: Text(
                formatHangoutDateRelativePt(_occurredDate),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _saving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _occurredDate,
                        firstDate: DateTime(1970),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setState(() => _occurredDate = picked);
                      }
                    },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Text(
              'Fotos (opcional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _slots.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  if (i == _slots.length) {
                    return Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _saving ? null : _showImageSourceSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          width: 96,
                          height: 96,
                          child: Icon(Icons.add_photo_alternate_outlined, size: 40),
                        ),
                      ),
                    );
                  }
                  return _thumb(context, _slots[i], i);
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving ? null : _showImageSourceSheet,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Adicionar foto'),
            ),
          ],
        ),
      ),
    );
  }
}
