import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Mesure la durée réelle d'une vidéo tout juste sélectionnée.
///
/// `ImagePicker.pickVideo(maxDuration: ...)` ne borne que l'enregistrement
/// caméra — une vidéo déjà existante choisie depuis la galerie n'est pas
/// coupée à cette durée, d'où cette vérification a posteriori avant upload.
/// Retourne `null` si la durée n'a pas pu être déterminée (fichier
/// corrompu/format non lisible) : l'appelant choisit alors de laisser passer
/// plutôt que de bloquer un envoi légitime sur un simple échec de mesure.
Future<Duration?> probeVideoDuration(XFile file) async {
  final controller = kIsWeb
      ? VideoPlayerController.networkUrl(Uri.parse(file.path))
      : VideoPlayerController.file(File(file.path));
  try {
    await controller.initialize();
    return controller.value.duration;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}
