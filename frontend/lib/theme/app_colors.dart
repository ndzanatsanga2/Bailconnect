import 'package:flutter/material.dart';

/// Tokens repris du dossier de conception (section 8) — thème clair uniquement pour le MVP.
///
/// Direction visuelle : fonds neutres très pâles, vert Bailconnect pour la
/// navigation/en-têtes/actions principales, ocre en accent unique et
/// parcimonieux (CTA clés, éléments actifs). Gris neutres (sans teinte verte)
/// pour le texte secondaire et les séparateurs.
class AppColors {
  static const green = Color(0xFF0A7A4C);
  static const greenDark = Color(0xFF065C39);
  static const greenLight = Color(0xFFE3F3EA);
  static const amber = Color(0xFFE85D25);
  static const amberLight = Color(0xFFFCEEE2);
  static const ink = Color(0xFF0B1512);
  static const sub = Color(0xFF6B7280);
  static const line = Color(0xFFE7E9E6);
  static const bg = Color(0xFFF7F8F6);
  static const paper = Color(0xFFFFFFFF);
  static const whatsapp = Color(0xFF128C4B);
  static const gold = Color(0xFFD9A21B);
  static const danger = Color(0xFFC0392B);
  static const dangerLight = Color(0xFFFBEAEA);

  /// Ombre douce et diffuse des cartes — jamais de bordure dure.
  static const cardShadow = [
    BoxShadow(color: Color(0x0F0B1512), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x080B1512), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Légère élévation au survol (web/desktop).
  static const cardShadowHover = [
    BoxShadow(color: Color(0x1A0B1512), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0A0B1512), blurRadius: 4, offset: Offset(0, 2)),
  ];
}
