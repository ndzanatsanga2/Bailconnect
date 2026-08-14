/// Heuristique simple nom d'équipement → icône, pour la grille de la fiche
/// bien (le dossier de conception associe une icône par équipement mais le
/// modèle ne fige pas de vocabulaire fermé).
String amenityIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('clim')) return 'snow';
  if (lower.contains('parking') || lower.contains('garage')) return 'car';
  if (lower.contains('eau') || lower.contains('douche')) return 'shower';
  if (lower.contains('meublé') || lower.contains('meuble') || lower.contains('chambre')) return 'bed';
  return 'check';
}
