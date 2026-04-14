import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/idea.dart';
import 'ideas_labels.dart';

class IdeaEditorScreen extends ConsumerStatefulWidget {
  const IdeaEditorScreen({super.key, this.initial});

  final Idea? initial;

  @override
  ConsumerState<IdeaEditorScreen> createState() => _IdeaEditorScreenState();
}

class _IdeaEditorScreenState extends ConsumerState<IdeaEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  IdeaCategory? _category;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _category = e?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final title = _titleController.text.trim();
      final desc = _descriptionController.text.trim();
      final description = desc.isEmpty ? null : desc;

      if (_isEdit) {
        await repo.updateIdea(
          existing: widget.initial!,
          title: title,
          description: description,
          category: _category,
        );
      } else {
        await repo.createIdea(
          profile: profile,
          title: title,
          description: description,
          category: _category,
        );
      }
      ref.invalidate(ideasProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Ideia atualizada.' : 'Ideia salva.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar ideia' : 'Nova ideia'),
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
                labelText: 'Descrição (opcional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<IdeaCategory?>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<IdeaCategory?>(
                  value: null,
                  child: Text('Nenhuma'),
                ),
                ...ideaCategoryPickerOrder().map(
                  (c) => DropdownMenuItem<IdeaCategory?>(
                    value: c,
                    child: Text(ideaCategoryLabelPt(c)),
                  ),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _category = v),
            ),
          ],
        ),
      ),
    );
  }
}
