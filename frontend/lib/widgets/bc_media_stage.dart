import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Affiche un média (photo ou vidéo) en entier, sans rognage — le premier
/// plan est ajusté par contenance (aucune coupe, quelle que soit
/// l'orientation portrait/paysage) et centré sur un arrière-plan flouté et
/// agrandi du même média, façon TikTok/Instagram, pour éviter les bandes
/// noires brutes. [cover] et [contain] doivent représenter le même média,
/// juste ajusté différemment (voir [bcVideoFit] pour la variante vidéo).
class BcMediaStage extends StatelessWidget {
  final Widget cover;
  final Widget contain;

  const BcMediaStage({super.key, required this.cover, required this.contain});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: cover,
        ),
        // Assombrit l'arrière-plan flouté pour que le média net au premier
        // plan (peint par-dessus, dans ses propres bornes) reste lisible.
        const ColoredBox(color: Color(0x52000000)),
        Center(child: contain),
      ],
    );
  }
}

/// Construit la variante [fit] d'une vidéo à partir du même [controller] —
/// deux instances de [VideoPlayer] liées au même contrôleur restent
/// synchronisées (aucun décodage supplémentaire), l'une en `cover` pour le
/// fond, l'autre en `contain` pour le premier plan.
Widget bcVideoFit(VideoPlayerController controller, BoxFit fit) {
  return FittedBox(
    fit: fit,
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      width: controller.value.size.width,
      height: controller.value.size.height,
      child: VideoPlayer(controller),
    ),
  );
}
