import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hangout_conflict.dart';
import '../../core/providers.dart';
import '../../data/models/availability.dart';
import 'hangouts_format.dart';

class AvailabilityEditorScreen extends ConsumerStatefulWidget {
  const AvailabilityEditorScreen({super.key, this.initial});

  final Availability? initial;

  @override
  ConsumerState<AvailabilityEditorScreen> createState() =>
      _AvailabilityEditorScreenState();
}

class _AvailabilityEditorScreenState
    extends ConsumerState<AvailabilityEditorScreen> {
  late int _weekday;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _weekday = e?.weekday ?? DateTime.now().weekday;
    _start = e != null ? parseTimeHhMm(e.startTime) : const TimeOfDay(hour: 9, minute: 0);
    _end = e != null ? parseTimeHhMm(e.endTime) : const TimeOfDay(hour: 12, minute: 0);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    final startStr = formatTimeOfDay(_start);
    final endStr = formatTimeOfDay(_end);
    if (hhmmToMinutes(startStr) >= hhmmToMinutes(endStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O horário final precisa ser depois do inicial.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      if (_isEdit) {
        await repo.updateAvailability(
          existing: widget.initial!,
          profile: profile,
          weekday: _weekday,
          startTime: startStr,
          endTime: endStr,
        );
      } else {
        await repo.createAvailability(
          profile: profile,
          weekday: _weekday,
          startTime: startStr,
          endTime: endStr,
        );
      }
      ref.invalidate(availabilitiesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Faixa atualizada.' : 'Faixa salva.')),
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

  Future<void> _delete() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir faixa?'),
        content: const Text('Remove só para você; os outros não são afetados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).deleteAvailability(
            existing: widget.initial!,
            profile: profile,
          );
      ref.invalidate(availabilitiesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faixa removida.')),
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
        title: Text(_isEdit ? 'Editar indisponibilidade' : 'Nova indisponibilidade'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Text(
            'Só você edita suas faixas; todo mundo vê na visão consolidada.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use — precisamos de seleção controlada por estado.
            value: _weekday,
            decoration: const InputDecoration(
              labelText: 'Dia da semana',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var d = 1; d <= 7; d++)
                DropdownMenuItem(value: d, child: Text(weekdayLabelPt(d))),
            ],
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) setState(() => _weekday = v);
                  },
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Início'),
            subtitle: Text(formatTimeOfDay(_start)),
            trailing: const Icon(Icons.schedule),
            onTap: _saving ? null : () => _pickTime(isStart: true),
          ),
          ListTile(
            title: const Text('Fim'),
            subtitle: Text(formatTimeOfDay(_end)),
            trailing: const Icon(Icons.schedule),
            onTap: _saving ? null : () => _pickTime(isStart: false),
          ),
        ],
      ),
    );
  }
}
