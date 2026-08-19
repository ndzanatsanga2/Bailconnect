/// Limites appliquées côté client à l'upload de médias d'annonce (photo/
/// vidéo), réutilisées par les écrans de publication annonceur et admin.
library;

/// Durée max d'une vidéo — imposée au picker (ImagePicker.pickVideo).
const kMaxVideoDuration = Duration(seconds: 60);

/// Taille max d'un fichier média (photo ou vidéo), en octets — rejeté avant
/// upload si dépassé (pas de compression disponible côté client).
const kMaxMediaFileSizeBytes = 40 * 1024 * 1024;
