import 'package:flutter/material.dart';

/// Dégradés placeholder pour les vignettes photo/vidéo tant qu'aucun média
/// réel n'est disponible — repris du dossier de conception (classes .g1-.g5).
class AppGradients {
  static const g1 = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF123F2C), Color(0xFF0A7A4C), Color(0xFF5CC191)],
    stops: [0.0, 0.55, 1.0],
  );
  static const g2 = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF7A3512), Color(0xFFE85D25), Color(0xFFF6A877)],
    stops: [0.0, 0.6, 1.0],
  );
  static const g3 = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF16324C), Color(0xFF2F6EA5), Color(0xFF8FBFE6)],
    stops: [0.0, 0.55, 1.0],
  );
  static const g4 = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF3D2650), Color(0xFF7A45A0), Color(0xFFC69FE0)],
    stops: [0.0, 0.55, 1.0],
  );
  static const g5 = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF4A3510), Color(0xFFB78A2A), Color(0xFFE8CF8F)],
    stops: [0.0, 0.55, 1.0],
  );

  static const all = [g1, g2, g3, g4, g5];
}
