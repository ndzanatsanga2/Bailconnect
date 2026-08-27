/// Limites appliquées côté client à l'upload de médias d'annonce (photo/
/// vidéo), réutilisées par les écrans de publication annonceur et admin.
library;

/// Durée max d'une vidéo — passée au picker (ImagePicker.pickVideo, effectif
/// seulement pour un enregistrement caméra) et revérifiée après sélection
/// via probeVideoDuration() (video_duration.dart) — une vidéo existante de
/// la galerie n'est pas bornée par le picker.
const kMaxVideoDuration = Duration(seconds: 90);

/// Taille max d'un fichier média (photo ou vidéo), en octets — rejeté avant
/// upload si dépassé. 150 Mo couvre une vidéo de [kMaxVideoDuration] en
/// qualité correcte (~1080p) ; pas de compression disponible côté client —
/// à envisager côté serveur si les uploads s'avèrent trop lourds pour le
/// plan gratuit.
const kMaxMediaFileSizeBytes = 150 * 1024 * 1024;
