import 'package:flutter/material.dart';

/// Paleta curada (grupos curtos por grafema) para as impressões do trio.
const List<String> kTimelineReactionEmojiPalette = [
  // Amor & festa
  '❤️', '💕', '💖', '💗', '💘', '💝', '🤍', '🖤', '💙', '💚', '💛', '🧡',
  '💜', '🤎', '🩷', '🩵', '✨', '💫', '🌟', '⭐', '🎉', '🎊', '🥳', '🔥',
  // Rostos
  '😂', '😍', '🥰', '😊', '🤗', '😎', '🥲', '😭', '🤩', '🫠', '😘', '🥹',
  '😇', '🤓', '🤔', '🫡', '🤫', '🤐', '🤯', '😴', '🥱', '🤤', '😋', '🤪',
  // Gestos
  '👏', '🙌', '🫶', '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤙', '👋', '🫰',
  '💪', '🙏', '✋', '🤝', '👀', '💤', '🫂',
  // Natureza & tempo
  '💐', '🌈', '☀️', '🌙', '☁️', '⛅', '🌧️', '❄️', '🌊', '🌴', '🍀', '🌸',
  '🌺', '🌻', '🌷', '🥀', '🍂', '🌿', '🦋', '🐝', '⚡', '🔔',
  // Comida & bebida
  '☕', '🍕', '🍰', '🍫', '🧁', '🍿', '🍩', '🥐', '🍓', '🍉', '🍷', '🧋',
  '🥞', '🧇', '🍜', '🍣', '🥗', '🍔', '🌮', '🍦',
  // Animais
  '🐱', '🐶', '🦊', '🐻', '🐼', '🐸', '🦁', '🐯', '🐰', '🐣', '🐧', '🐙',
  // Objetos & momentos
  '🎵', '📸', '✈️', '🚀', '🛸', '⛵', '🚲', '🏠', '💼', '📚', '💡', '🎁',
  '🎀', '🏆', '🎮', '🎯', '🎪', '🥇', '🥈', '🥉', '🔮', '💎', '🗺️', '🧳',
];

Future<String?> showTimelineReactionPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final sheetH = MediaQuery.sizeOf(ctx).height;
      final gridHeight = (sheetH * 0.42).clamp(240.0, 420.0);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escolhe um emoji',
                style: Theme.of(ctx).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: kTimelineReactionEmojiPalette.length,
                  itemBuilder: (context, i) {
                    final e = kTimelineReactionEmojiPalette[i];
                    return Semantics(
                      button: true,
                      label: 'Emoji $e',
                      child: Material(
                        color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(ctx, e),
                          child: Center(
                            child: Text(e, style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
