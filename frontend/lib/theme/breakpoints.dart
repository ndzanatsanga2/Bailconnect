import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;

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

/// true pour un build mobile natif (Android/iOS) — false sur web. Signal de
/// plateforme pur, sans notion de largeur d'écran : sur le web, une PWA
/// installée sur téléphone reste "web" ([kIsWeb] = true) au sens de cette
/// constante. Utilisée uniquement comme valeur par défaut (const) là où
/// [isMobileLayout] ne peut pas s'appliquer faute de [BuildContext] — dans
/// tout code avec accès au contexte, préférer [isMobileLayout].
const kIsMobileApp = !kIsWeb;

/// true si l'app doit se comporter comme sur mobile : accès à l'espace
/// client, jamais à la landing/back-office web. Toujours vrai en build natif
/// ; sur le web, vrai uniquement en dessous de [kMobileBreakpoint] — couvre
/// le cas de la PWA installée sur téléphone, où [kIsWeb] reste vrai mais
/// l'écran est étroit. Dépend de [MediaQuery] : se recalcule automatiquement
/// si la fenêtre est redimensionnée.
bool isMobileLayout(BuildContext context) =>
    !kIsWeb || MediaQuery.of(context).size.width < kMobileBreakpoint;

/// Largeur de la colonne centrée façon mobile pour l'espace client sur
/// desktop/tablette (fil, recherche, favoris, profil, connexion...).
const kClientFrameWidth = 460.0;

/// Largeur max du contenu dans les espaces bailleur/admin (desktop), pour
/// éviter l'étirement plein écran sur les grands moniteurs.
const kDesktopContentMaxWidth = 1200.0;
