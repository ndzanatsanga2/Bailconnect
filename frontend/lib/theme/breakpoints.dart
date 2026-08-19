import 'package:flutter/foundation.dart' show kIsWeb;

/// Points de rupture centralisés, réutilisés par tous les layouts
/// responsive de l'app (espace client, bailleur, admin).
///
/// - < [kMobileBreakpoint] : mobile — layout natif, aucun recadrage.
/// - < [kTabletBreakpoint] : tablette — bascule sur le layout compact
///   (mobile pour bailleur/admin, cadre centré pour le client).
/// - >= [kTabletBreakpoint] : desktop — sidebar fixe (bailleur/admin) ou
///   fond neutre autour d'une colonne centrée (client).
const kMobileBreakpoint = 600.0;
const kTabletBreakpoint = 860.0;

/// true pour un build mobile natif (Android/iOS) — false sur web, y compris
/// dans un navigateur affiché en largeur mobile (voir [kMobileBreakpoint],
/// orthogonale à cette détection de plateforme). Sert à exclure le
/// back-office admin du build mobile.
const kIsMobileApp = !kIsWeb;

/// Largeur de la colonne centrée façon mobile pour l'espace client sur
/// desktop/tablette (fil, recherche, favoris, profil, connexion...).
const kClientFrameWidth = 460.0;

/// Largeur max du contenu dans les espaces bailleur/admin (desktop), pour
/// éviter l'étirement plein écran sur les grands moniteurs.
const kDesktopContentMaxWidth = 1200.0;
