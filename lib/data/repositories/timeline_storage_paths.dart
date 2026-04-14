/// Bucket e convenção de paths para imagens da timeline (Supabase Storage).
const kTimelineImagesBucket = 'timeline-images';

String timelineCoverObjectPath(String eventId, String ext) =>
    'events/$eventId/cover.${ext.toLowerCase()}';

/// Nova foto em um evento (nome único no storage).
String timelineImageObjectPath(String eventId, String objectId, String ext) =>
    'events/$eventId/$objectId.${ext.toLowerCase()}';

/// Extrai o path do objeto a partir da URL pública do Supabase Storage.
String? storagePathFromPublicUrl(String url, {String bucket = kTimelineImagesBucket}) {
  final marker = '/object/public/$bucket/';
  final i = url.indexOf(marker);
  if (i == -1) return null;
  return url.substring(i + marker.length);
}
