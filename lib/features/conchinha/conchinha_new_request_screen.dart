import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/places/google_places_client.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/conchinha_address.dart';
import '../../data/repositories/noop_repository.dart';

/// Busca de endereço (Places se houver chave) + resumo estilo “confirmar corrida”.
class ConchinhaNewRequestScreen extends ConsumerStatefulWidget {
  const ConchinhaNewRequestScreen({super.key});

  @override
  ConsumerState<ConchinhaNewRequestScreen> createState() => _ConchinhaNewRequestScreenState();
}

class _ConchinhaNewRequestScreenState extends ConsumerState<ConchinhaNewRequestScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  bool _loadingPredictions = false;
  ConchinhaAddress? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _scheduleAutocomplete() {
    _debounce?.cancel();
    if (!GooglePlacesClient.isConfigured) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      final q = _search.text;
      setState(() => _loadingPredictions = true);
      final list = await GooglePlacesClient.autocomplete(q);
      if (!mounted) return;
      setState(() {
        _predictions = list;
        _loadingPredictions = false;
      });
    });
  }

  Future<void> _pickPrediction(PlacePrediction p) async {
    setState(() {
      _loadingPredictions = true;
      _predictions = [];
    });
    final addr = await GooglePlacesClient.placeDetails(p.placeId);
    if (!mounted) return;
    setState(() {
      _loadingPredictions = false;
      _selected = addr;
      if (addr != null) {
        _search.text = addr.label;
      }
    });
  }

  void _useManualText() {
    final t = _search.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _selected = ConchinhaAddress(label: t);
      _predictions = [];
    });
  }

  Future<void> _submit() async {
    final profile = ref.read(userProfileProvider);
    final addr = _selected;
    if (profile == null || addr == null) return;
    final repo = ref.read(repositoryProvider);
    if (repo is NoopRepository) return;
    try {
      final id = await repo.createConchinhaRequest(requester: profile, address: addr);
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _selected != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedir conchinha'),
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              GooglePlacesClient.isConfigured
                  ? 'Busque um endereço ou confirme o texto abaixo.'
                  : 'Sem chave do Google Maps: descreva o lugar em texto (bairro, ponto de encontro etc.).',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: GooglePlacesClient.isConfigured
                    ? 'Rua, bairro, estabelecimento…'
                    : 'Onde você precisa de companhia?',
                border: const OutlineInputBorder(),
                suffixIcon: _loadingPredictions
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (_) {
                setState(() {});
                if (GooglePlacesClient.isConfigured) {
                  _scheduleAutocomplete();
                }
              },
            ),
          ),
          if (!GooglePlacesClient.isConfigured && _search.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _useManualText,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Usar este texto como endereço'),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (GooglePlacesClient.isConfigured && _predictions.isNotEmpty) ...[
                  for (final p in _predictions) ...[
                    ListTile(
                      title: Text(p.description),
                      onTap: () => unawaited(_pickPrediction(p)),
                    ),
                    const Divider(height: 1),
                  ],
                ],
                if (_selected != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selected!.lat != null &&
                              _selected!.lng != null &&
                              GooglePlacesClient.staticMapUrl(
                                    lat: _selected!.lat!,
                                    lng: _selected!.lng!,
                                  ) !=
                                  null)
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                GooglePlacesClient.staticMapUrl(
                                  lat: _selected!.lat!,
                                  lng: _selected!.lng!,
                                )!,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 140,
                              color: theme.colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.map_outlined,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumo',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selected!.label,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: canSubmit ? _submit : null,
            child: const Text('Pedir conchinha'),
          ),
        ),
      ),
    );
  }
}
