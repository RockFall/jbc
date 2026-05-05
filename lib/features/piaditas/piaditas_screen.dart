import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/piaditas/inside_joke_body.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/noop_repository.dart';

/// Modo Piaditas: pote central, depositar texto e lista “Abrir o pote” (Epic 13).
class PiaditasScreen extends ConsumerStatefulWidget {
  const PiaditasScreen({super.key});

  @override
  ConsumerState<PiaditasScreen> createState() => _PiaditasScreenState();
}

class _PiaditasScreenState extends ConsumerState<PiaditasScreen>
    with SingleTickerProviderStateMixin {
  final _bodyController = TextEditingController();
  late final AnimationController _depositAnim;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _depositAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _depositAnim.dispose();
    super.dispose();
  }

  Future<void> _deposit() async {
    final me = ref.read(userProfileProvider);
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione seu perfil antes de depositar.')),
      );
      return;
    }
    if (ref.read(repositoryProvider) is NoopRepository) return;

    String normalized;
    try {
      normalized = InsideJokeBody.normalize(_bodyController.text);
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).createInsideJoke(author: me, body: normalized);
      _bodyController.clear();
      ref.invalidate(insideJokesProvider);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua piada foi guardada no pote.')),
      );
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (!reduceMotion) {
        unawaited(_depositAnim.forward(from: 0).then((_) {
          if (mounted) _depositAnim.reset();
        }));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jokesAsync = ref.watch(insideJokesProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piaditas'),
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
      ),
      body: ref.watch(repositoryProvider) is NoopRepository
          ? const Center(child: Text('Configure o Supabase para usar o pote.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      children: [
                        Text(
                          'Nossas piadas internas.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: AnimatedBuilder(
                            animation: _depositAnim,
                            builder: (context, _) {
                              final v = _depositAnim.value;
                              final curved = Curves.elasticOut.transform(v);
                              final scale = reduceMotion
                                  ? 1.0
                                  : (1.0 + 0.12 * math.pow(math.sin(curved * math.pi), 2)).toDouble();
                              final sparkOpacity =
                                  reduceMotion ? 0.0 : (1.0 - curved).clamp(0.0, 1.0);
                              return Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Transform.scale(
                                    scale: scale,
                                    child: CustomPaint(
                                      size: const Size(200, 200),
                                      painter: const _PotPainter(),
                                    ),
                                  ),
                                  if (sparkOpacity > 0.04)
                                    for (var k = 0; k < 6; k++)
                                      Positioned(
                                        top: 24 + curved * 32 * (k % 3),
                                        left: 28 + k * 24.0 + math.sin(curved * math.pi + k) * 10,
                                        child: Opacity(
                                          opacity: sparkOpacity,
                                          child: Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 12 + k * 1.5,
                                            color: scheme.tertiary,
                                          ),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _bodyController,
                          minLines: 3,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Escreva a piada que quer guardar no pote…',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brandRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _saving ? null : _deposit,
                          icon: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.savings_outlined),
                          label: Text(_saving ? 'Salvando…' : 'Guardar no pote'),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Abrir o pote',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: jokesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erro: $e')),
                    data: (jokes) {
                      if (jokes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: scheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'O pote está vazio — a primeira piada vai doer (de rir).',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final fmt = DateFormat("dd/MM/yy 'às' HH:mm");
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: jokes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final j = jokes[i];
                          final who = JbcProfile.displayNameForStorageKey(j.authorKey);
                          return Material(
                            color: const Color(0xFFFFF9F4),
                            elevation: 1,
                            shadowColor: Colors.black12,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                title: Text(
                                  j.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '$who · ${fmt.format(j.createdAt.toLocal())}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SelectableText(
                                      j.body,
                                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Jarro simples (sem assets externos).
class _PotPainter extends CustomPainter {
  const _PotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final jarPaint = Paint()..color = const Color(0xFF7E5748);
    final jar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.58), width: w * 0.62, height: h * 0.48),
      const Radius.circular(22),
    );
    canvas.drawRRect(jar, jarPaint);

    final lidPaint = Paint()..color = const Color(0xFF5D4037);
    final lid = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, h * 0.28), width: w * 0.68, height: h * 0.14),
      const Radius.circular(14),
    );
    canvas.drawRRect(lid, lidPaint);

    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.14, h * 0.55), width: w * 0.12, height: h * 0.22),
      gloss,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
