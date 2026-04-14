import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/noop_repository.dart';

/// Ferramentas perigosas só para o perfil Caio.
class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final repo = ref.read(repositoryProvider);

    Future<void> clearDb() async {
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Limpar banco de dados?'),
          content: const Text(
            'Esta ação apaga memórias, rolês, ideias e indisponibilidades no Supabase '
            'para todos os perfis. Não há desfazer.\n\n'
            'Imagens antigas no storage podem continuar órfãs até limpeza manual.\n\n'
            'Só use se tiver certeza.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar tudo'),
            ),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
      try {
        await repo.clearAllRemoteData();
        ref.invalidate(timelineEventsProvider);
        ref.invalidate(hangoutsProvider);
        ref.invalidate(ideasProvider);
        ref.invalidate(availabilitiesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados remotos apagados.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }

    Future<void> loadDefault() async {
      if (profile == null) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Carregar dados default?'),
          content: const Text(
            'Serão criadas várias memórias na linha do tempo a partir do arquivo embutido, '
            'sem apagar o que já existe.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Carregar')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      try {
        final raw = await rootBundle.loadString('assets/seed/timeline_default.json');
        await repo.importTimelineEventsFromJson(profile: profile, json: raw);
        ref.invalidate(timelineEventsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memórias default inseridas.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de Desenvolvedor')),
      body: ListView(
        children: [
          if (repo is NoopRepository)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Supabase não está configurado: as ações abaixo não funcionam até definir '
                    'SUPABASE_URL e SUPABASE_ANON_KEY.',
                  ),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Limpar banco de dados'),
            subtitle: const Text('Remove todos os registros JBC no projeto Supabase'),
            onTap: clearDb,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Carregar dados default'),
            subtitle: const Text('Insere a timeline de exemplo (arquivo JSON)'),
            onTap: loadDefault,
          ),
        ],
      ),
    );
  }
}
