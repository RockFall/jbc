/// Sticker curado (emoji grande) para a emoção do momento — Epic 14.
class MomentSticker {
  const MomentSticker({
    required this.id,
    required this.emoji,
    required this.labelPt,
    required this.categoryPt,
  });

  final String id;
  final String emoji;
  final String labelPt;
  final String categoryPt;
}

abstract final class MomentStickerCatalog {
  static const List<MomentSticker> all = [
    MomentSticker(id: 'radiante', emoji: '😄', labelPt: 'Radiante', categoryPt: 'Feliz'),
    MomentSticker(id: 'tranquilo', emoji: '😌', labelPt: 'Tranquilo', categoryPt: 'Calmo'),
    MomentSticker(id: 'apaixonado', emoji: '🥰', labelPt: 'Apaixonado', categoryPt: 'Carinho'),
    MomentSticker(id: 'animado', emoji: '🤩', labelPt: 'Animado', categoryPt: 'Feliz'),
    MomentSticker(id: 'cansado', emoji: '😮‍💨', labelPt: 'Cansado', categoryPt: 'Cansado'),
    MomentSticker(id: 'sono', emoji: '😴', labelPt: 'Com sono', categoryPt: 'Cansado'),
    MomentSticker(id: 'ansioso', emoji: '😰', labelPt: 'Ansioso', categoryPt: 'Tenso'),
    MomentSticker(id: 'pensativo', emoji: '🤔', labelPt: 'Pensativo', categoryPt: 'Tenso'),
    MomentSticker(id: 'determinado', emoji: '💪', labelPt: 'Determinado', categoryPt: 'Energia'),
    MomentSticker(id: 'fofo', emoji: '🐱', labelPt: 'Modo gatinho', categoryPt: 'Carinho'),
    MomentSticker(id: 'festa', emoji: '🎉', labelPt: 'Modo festa', categoryPt: 'Feliz'),
    MomentSticker(id: 'chill', emoji: '😎', labelPt: 'De boa', categoryPt: 'Calmo'),
    MomentSticker(id: 'choramingas', emoji: '🥺', labelPt: 'Saudades', categoryPt: 'Carinho'),
    MomentSticker(id: 'zangado', emoji: '😤', labelPt: 'Irritado', categoryPt: 'Tenso'),
    MomentSticker(id: 'doente', emoji: '🤒', labelPt: 'Indisposto', categoryPt: 'Cansado'),
    MomentSticker(id: 'surpreso', emoji: '😲', labelPt: 'Surpreso', categoryPt: 'Tenso'),
    MomentSticker(id: 'grato', emoji: '🙏', labelPt: 'Grato', categoryPt: 'Calmo'),
    MomentSticker(id: 'foco', emoji: '🎯', labelPt: 'No foco', categoryPt: 'Energia'),
    MomentSticker(id: 'comilao', emoji: '🍕', labelPt: 'Com fome', categoryPt: 'Energia'),
    MomentSticker(id: 'misterioso', emoji: '🫣', labelPt: 'Tímido', categoryPt: 'Tenso'),
  ];

  static MomentSticker? tryById(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static bool isValidId(String id) => tryById(id) != null;
}
