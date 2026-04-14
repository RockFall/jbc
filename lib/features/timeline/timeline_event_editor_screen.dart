import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/timeline_event.dart';

class _ImageSlot {
  _ImageSlot.network(this.url) : bytes = null, file = null;
  _ImageSlot.local(this.bytes, this.file) : url = null;

  final String? url;
  final Uint8List? bytes;
  final XFile? file;
}

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
  final List<_ImageSlot> _slots = [];
  int _primaryIndex = 0;
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
      for (final u in e.imageUrls) {
        if (u.trim().isNotEmpty) _slots.add(_ImageSlot.network(u.trim()));
      }
      _primaryIndex = e.primaryImageIndex.clamp(0, _slots.isEmpty ? 0 : _slots.length - 1);
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

  List<TimelineImageInput> _inputsForSave() {
    final out = <TimelineImageInput>[];
    for (final s in _slots) {
      if (s.url != null) {
        out.add(TimelineImageInput.existing(s.url!));
      } else if (s.bytes != null) {
        var ext = s.file != null
            ? p.extension(s.file!.path).replaceFirst('.', '')
            : 'jpg';
        if (ext.isEmpty) ext = 'jpg';
        out.add(TimelineImageInput.upload(s.bytes!, ext));
      }
    }
    return out;
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
      final inputs = _inputsForSave();
      final pIdx = _slots.isEmpty ? 0 : _primaryIndex.clamp(0, _slots.length - 1);

      if (_isEdit) {
        await repo.updateTimelineEvent(
          existing: widget.initial!,
          occurredAt: occurred,
          title: title,
          description: description,
          images: inputs,
          primaryImageIndex: pIdx,
        );
      } else {
        await repo.createManualTimelineEvent(
          profile: profile,
          occurredAt: occurred,
          title: title,
          description: description,
          images: inputs,
          primaryImageIndex: pIdx,
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

  Widget _thumb(BuildContext context, _ImageSlot s, int index) {
    final isPrimary = _slots.isNotEmpty && index == _primaryIndex;
    Widget image;
    if (s.bytes != null) {
      image = Image.memory(s.bytes!, fit: BoxFit.cover);
    } else if (s.url != null) {
      image = Image.network(
        s.url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined),
      );
    } else {
      image = const SizedBox.shrink();
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 96,
            height: 96,
            child: image,
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
              'Fotos (opcional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Toque na estrela para definir a foto principal na linha do tempo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
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
