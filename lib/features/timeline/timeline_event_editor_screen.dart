import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/timeline_event.dart';

class TimelineEventEditorScreen extends ConsumerStatefulWidget {
  const TimelineEventEditorScreen({super.key, this.initial});

  final TimelineEvent? initial;

  @override
  ConsumerState<TimelineEventEditorScreen> createState() =>
      _TimelineEventEditorScreenState();
}

class _TimelineEventEditorScreenState
    extends ConsumerState<TimelineEventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _occurredDate;
  XFile? _pickedImage;
  Uint8List? _pickedBytes;
  bool _removeImage = false;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      final local = e.occurredAt.toLocal();
      _occurredDate = DateTime(local.year, local.month, local.day);
    } else {
      final n = DateTime.now();
      _occurredDate = DateTime(n.year, n.month, n.day);
    }
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
        _removeImage = false;
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
              if (_isEdit &&
                  (widget.initial!.imageUrl != null ||
                      _pickedBytes != null))
                ListTile(
                  leading: Icon(
                    Icons.hide_image_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Remover imagem',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                      _pickedBytes = null;
                      _removeImage = true;
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
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha um perfil nas configurações.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final occurred = _occurredAtForSave();

      List<int>? bytes;
      String? ext;
      if (_pickedBytes != null) {
        bytes = _pickedBytes;
        ext = _pickedImage != null
            ? p.extension(_pickedImage!.path).replaceFirst('.', '')
            : 'jpg';
        if (ext.isEmpty) ext = 'jpg';
      }

      if (_isEdit) {
        await repo.updateTimelineEvent(
          existing: widget.initial!,
          occurredAt: occurred,
          title: title,
          description: description,
          newImageBytes: bytes,
          newImageExtension: ext,
          removeImage: _removeImage,
        );
      } else {
        await repo.createManualTimelineEvent(
          profile: profile,
          occurredAt: occurred,
          title: title,
          description: description,
          imageBytes: bytes,
          imageExtension: ext,
        );
      }

      ref.invalidate(timelineEventsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Memória atualizada.' : 'Memória salva.')),
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

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir memória?'),
        content: const Text(
          'Isso remove a memória para todo mundo. Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).deleteTimelineEvent(widget.initial!);
      ref.invalidate(timelineEventsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memória excluída.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildImagePreview() {
    if (_pickedBytes != null) {
      return Image.memory(
        _pickedBytes!,
        fit: BoxFit.cover,
      );
    }
    final url = (!_removeImage) ? widget.initial?.imageUrl : null;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 48),
        ),
      );
    }
    return Center(
      child: Icon(
        Icons.add_a_photo_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  String _formatDt(DateTime utc) {
    final local = utc.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    final existingUrl = initial?.imageUrl;
    final hasVisualImage = _pickedBytes != null ||
        (!_removeImage && existingUrl != null && existingUrl.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar memória' : 'Nova memória'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _confirmDelete,
            ),
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
            if (initial?.origin == TimelineEventOrigin.fromHangout)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Chip(
                  avatar: const Icon(Icons.event, size: 18),
                  label: const Text('Vinda de um rolê'),
                ),
              ),
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe um título';
                return null;
              },
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
              label: Text(
                hasVisualImage ? 'Trocar foto' : 'Adicionar foto',
              ),
            ),
            if (_isEdit && initial != null) ...[
              const SizedBox(height: 24),
              Text(
                'Criada por ${JbcProfile.displayNameForStorageKey(initial.createdBy)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Registrada em ${_formatDt(initial.createdAt)} · '
                'Última edição ${_formatDt(initial.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
