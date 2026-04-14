import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/providers.dart';
import '../../data/models/hangout.dart';

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
  XFile? _pickedImage;
  Uint8List? _pickedBytes;
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
        _pickedImage = file;
        _pickedBytes = bytes;
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
              if (_pickedBytes != null)
                ListTile(
                  leading: Icon(
                    Icons.hide_image_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Remover foto',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                      _pickedBytes = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
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
      List<int>? bytes;
      String? ext;
      if (_pickedBytes != null) {
        bytes = _pickedBytes;
        ext = _pickedImage != null
            ? p.extension(_pickedImage!.path).replaceFirst('.', '')
            : 'jpg';
        if (ext.isEmpty) ext = 'jpg';
      }

      await ref.read(repositoryProvider).createTimelineFromHangout(
            hangout: h,
            profile: profile,
            occurredAt: _occurredAtForSave(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            imageBytes: bytes,
            imageExtension: ext,
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

  Widget _buildImagePreview() {
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!, fit: BoxFit.cover);
    }
    return Center(
      child: Icon(
        Icons.add_a_photo_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
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
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
              'Ajuste o texto e a foto antes de salvar. O vínculo com o rolê é automático.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quando aconteceu'),
              subtitle: Text(
                MaterialLocalizations.of(context).formatFullDate(_occurredDate),
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
              'Foto (opcional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _saving ? null : _showImageSourceSheet,
                  child: _buildImagePreview(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving ? null : _showImageSourceSheet,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_pickedBytes != null ? 'Trocar foto' : 'Adicionar foto'),
            ),
          ],
        ),
      ),
    );
  }
}
