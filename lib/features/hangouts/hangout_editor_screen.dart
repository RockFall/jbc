import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/hangout_conflict.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/hangout.dart';
import '../../data/models/idea.dart';
import '../ideas/ideas_labels.dart';
import 'hangout_memory_screen.dart';
import 'hangouts_format.dart';

class HangoutEditorScreen extends ConsumerStatefulWidget {
  const HangoutEditorScreen({
    super.key,
    this.initial,
    this.prefillFromIdea,
  }) : assert(
          initial == null || prefillFromIdea == null,
          'Não combine edição de rolê com pré-preenchimento de ideia.',
        );

  final Hangout? initial;

  /// Novo rolê a partir de uma ideia (título/descrição/categoria sugeridos).
  final Idea? prefillFromIdea;

  @override
  ConsumerState<HangoutEditorScreen> createState() => _HangoutEditorScreenState();
}

class _HangoutEditorScreenState extends ConsumerState<HangoutEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late DateTime _date;
  late TimeOfDay _start;
  TimeOfDay? _end;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;
  Hangout? get _h => widget.initial;

  @override
  void initState() {
    super.initState();
    final h = widget.initial;
    final idea = widget.prefillFromIdea;

    if (h != null) {
      _titleController = TextEditingController(text: h.title);
      _descriptionController = TextEditingController(text: h.description ?? '');
      _notesController = TextEditingController(text: h.notes ?? '');
      final d = h.date.toLocal();
      _date = DateTime(d.year, d.month, d.day);
      _start = parseTimeHhMm(h.startTime);
      _end = h.endTime != null && h.endTime!.isNotEmpty
          ? parseTimeHhMm(h.endTime!)
          : null;
    } else if (idea != null) {
      _titleController = TextEditingController(text: idea.title);
      _descriptionController = TextEditingController(text: idea.description ?? '');
      final note = idea.category != null
          ? 'Ideia · ${ideaCategoryLabelPt(idea.category!)}'
          : '';
      _notesController = TextEditingController(text: note);
      final n = DateTime.now();
      _date = DateTime(n.year, n.month, n.day);
      _start = const TimeOfDay(hour: 18, minute: 0);
      _end = const TimeOfDay(hour: 22, minute: 0);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
      final n = DateTime.now();
      _date = DateTime(n.year, n.month, n.day);
      _start = const TimeOfDay(hour: 18, minute: 0);
      _end = const TimeOfDay(hour: 22, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _end ?? _start.replacing(hour: _start.hour + 2 > 23 ? 23 : _start.hour + 2),
    );
    if (t != null) setState(() => _end = t);
  }

  Future<void> _save() async {
    if (_h?.status == HangoutStatus.cancelled) return;
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    final startStr = formatTimeOfDay(_start);
    final endStr = _end != null ? formatTimeOfDay(_end!) : null;
    if (endStr != null &&
        hhmmToMinutes(startStr) >= hhmmToMinutes(endStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horário final precisa ser depois do início.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final notes = _notesController.text.trim();
      final desc = description.isEmpty ? null : description;
      final nts = notes.isEmpty ? null : notes;

      if (_isEdit) {
        await repo.updateHangout(
          existing: _h!,
          title: title,
          description: desc,
          date: _date,
          startTime: startStr,
          endTime: endStr,
          notes: nts,
        );
      } else {
        await repo.createHangout(
          profile: profile,
          title: title,
          description: desc,
          date: _date,
          startTime: startStr,
          endTime: endStr,
          notes: nts,
        );
        final fromIdea = widget.prefillFromIdea;
        if (fromIdea != null && mounted) {
          final markDone = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ideia na lista'),
              content: const Text(
                'Quer marcar a ideia como realizada? Você pode deixá-la ativa se ainda quiser vê-la no Cantinho.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Manter ativa'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Marcar como realizada'),
                ),
              ],
            ),
          );
          if (markDone == true && mounted) {
            await repo.updateIdeaStatus(
              existing: fromIdea,
              status: IdeaStatus.done,
            );
            ref.invalidate(ideasProvider);
          }
        }
      }
      ref.invalidate(hangoutsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Rolê atualizado.' : 'Rolê criado.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(HangoutStatus status) async {
    if (_h == null) return;
    final label = status == HangoutStatus.cancelled
        ? 'Cancelar este rolê?'
        : 'Marcar como aconteceu?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(
          status == HangoutStatus.cancelled
              ? 'O rolê ficará como cancelado para todos.'
              : 'Depois você pode registrar a memória na timeline.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).updateHangoutStatus(
            existing: _h!,
            status: status,
          );
      ref.invalidate(hangoutsProvider);
      if (!mounted) return;

      if (status == HangoutStatus.happened) {
        final register = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registrar na timeline?'),
            content: const Text(
              'Quer complementar título, texto e foto da memória agora?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Depois'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sim, registrar'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        final updated = _h!.copyWith(status: HangoutStatus.happened);
        if (register == true) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => HangoutMemoryScreen(hangout: updated),
            ),
          );
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openMemoryFromEditor() async {
    if (_h == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HangoutMemoryScreen(hangout: _h!),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = _h?.status == HangoutStatus.cancelled;
    final happened = _h?.status == HangoutStatus.happened;
    final hasMemory =
        _h?.timelineEventId != null && _h!.timelineEventId!.isNotEmpty;

    final availAsync = ref.watch(availabilitiesProvider);
    final startStr = formatTimeOfDay(_start);
    final endStr = _end != null ? formatTimeOfDay(_end!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Rolê' : 'Novo rolê'),
        actions: [
          if (!cancelled)
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
            if (cancelled)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Este rolê foi cancelado. Não dá para alterar ou virar memória.',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            availAsync.when(
              data: (list) {
                final keys = conflictingPersonKeys(
                  hangoutDateLocal: _date,
                  hangoutStartTime: startStr,
                  hangoutEndTime: endStr,
                  allAvailabilities: list,
                );
                if (keys.isEmpty) return const SizedBox.shrink();
                final names = keys.map(JbcProfile.displayNameForStorageKey).join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: theme.colorScheme.onTertiaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sobreposição com indisponibilidade de: $names. '
                              'Você ainda pode salvar o rolê.',
                              style: TextStyle(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            if (_isEdit) ...[
              Row(
                children: [
                  Chip(
                    label: Text(hangoutStatusLabelPt(_h!.status)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Por ${JbcProfile.displayNameForStorageKey(_h!.createdBy)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: cancelled || _saving ? null : _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Início'),
              subtitle: Text(startStr),
              trailing: const Icon(Icons.schedule),
              onTap: cancelled || _saving ? null : _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fim (opcional)'),
              subtitle: Text(endStr ?? 'Não definido — conflitos usam 1 h a partir do início'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_end != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: cancelled || _saving ? null : () => setState(() => _end = null),
                    ),
                  const Icon(Icons.schedule),
                ],
              ),
              onTap: cancelled || _saving ? null : _pickEnd,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              readOnly: cancelled,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              readOnly: cancelled,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              readOnly: cancelled,
            ),
            if (_isEdit && !cancelled) ...[
              const SizedBox(height: 24),
              if (_h!.status == HangoutStatus.planned) ...[
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _setStatus(HangoutStatus.cancelled),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar rolê'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _saving ? null : () => _setStatus(HangoutStatus.happened),
                  icon: const Icon(Icons.celebration_outlined),
                  label: const Text('Marcar como aconteceu'),
                ),
              ],
              if (happened) ...[
                if (hasMemory)
                  Chip(
                    avatar: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Memória registrada na timeline'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _saving ? null : _openMemoryFromEditor,
                    icon: const Icon(Icons.favorite_outline),
                    label: const Text('Registrar na timeline'),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
