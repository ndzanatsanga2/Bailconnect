import 'package:flutter/material.dart';

import '../../../data/auth_repository.dart';
import '../../../data/lead_repository.dart';
import '../../../data/listing_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/bc_button.dart';
import '../../../widgets/bc_icon.dart';

/// Contenu partagé entre les vues mobile et web de l'espace bailleur pour
/// les onglets Demandes / Statistiques / Profil (seul « Biens » diffère,
/// carte vs tableau, fidèle aux deux vues du dossier de conception).
class AnnonceurDemandesList extends StatelessWidget {
  final List<ReceivedLead> leads;
  final ValueChanged<int> onMarkRead;
  final void Function(ReceivedLead lead) onReply;

  const AnnonceurDemandesList({
    super.key,
    required this.leads,
    required this.onMarkRead,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BcIcon('inbox', size: 40, color: AppColors.sub),
              const SizedBox(height: 14),
              const Text(
                'Aucune demande reçue pour l\'instant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Les locataires intéressés par vos biens apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.sub),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final lead = leads[index];
        return InkWell(
          onTap: lead.isRead ? null : () => onMarkRead(lead.id),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lead.isRead ? AppColors.paper : AppColors.greenLight,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.listingTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lead.neighborhood} · ${lead.tenantIdentifier}',
                        style: const TextStyle(
                          color: AppColors.sub,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!lead.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                BcButton(
                  label: 'Répondre',
                  icon: 'chat',
                  expand: false,
                  variant: BcButtonVariant.ghost,
                  onPressed: () => onReply(lead),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnnonceurStatsView extends StatelessWidget {
  final List<Listing> listings;
  final List<ReceivedLead> leads;

  const AnnonceurStatsView({
    super.key,
    required this.listings,
    required this.leads,
  });

  @override
  Widget build(BuildContext context) {
    final actives = listings.where((l) => l.status == 'publiee').length;
    final enAttente = listings.where((l) => l.status == 'en_attente').length;
    final louees = listings.where((l) => l.status == 'louee').length;
    final unread = leads.where((l) => !l.isRead).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _tile('${listings.length}', 'Annonces au total'),
          _tile('$actives', 'Publiées'),
          _tile('$enAttente', 'En validation'),
          _tile('$louees', 'Louées'),
          _tile('${leads.length}', 'Demandes reçues'),
          _tile('$unread', 'Demandes non lues', highlighted: unread > 0),
        ],
      ),
    );
  }

  Widget _tile(String value, String label, {bool highlighted = false}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.amber : AppColors.paper,
        border: Border.all(
          color: highlighted ? AppColors.amber : AppColors.line,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: highlighted ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: highlighted ? Colors.white70 : AppColors.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AnnonceurProfilView extends StatelessWidget {
  final AuthUser? user;
  final VoidCallback onLogout;
  final VoidCallback onBackToClient;

  const AnnonceurProfilView({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onBackToClient,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    // Un compte bailleur pur (inscrit directement comme annonceur) n'a pas
    // de capacité client — seul un locataire ayant ajouté la capacité
    // annonceur (double casquette) peut basculer vers l'espace client.
    final hasClientCapability = u?.role == 'locataire';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.greenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: BcIcon('user', size: 19, color: AppColors.greenDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (u?.fullName.isNotEmpty ?? false)
                            ? u!.fullName
                            : (u?.email ?? u?.phoneNumber ?? 'Connecté'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u?.annonceurType == 'agent' ? 'Agent' : 'Bailleur',
                        style: const TextStyle(
                          color: AppColors.sub,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoRow(
                  'user',
                  'Prénom',
                  (u?.fullName.isEmpty ?? true) ? '—' : u!.fullName,
                ),
                _infoRow('chat', 'Email', u?.email ?? '—'),
                _infoRow('phone', 'Téléphone', u?.phoneNumber ?? '—'),
                _infoRow(
                  'phone',
                  'WhatsApp',
                  (u?.whatsappNumber.isEmpty ?? true) ? '—' : u!.whatsappNumber,
                ),
                _infoRow(
                  'grid',
                  'Type',
                  u?.annonceurType == 'agent' ? 'Agent' : 'Bailleur',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (hasClientCapability) ...[
            BcButton(
              label: 'Retour à l\'espace client',
              icon: 'home',
              variant: BcButtonVariant.ghost,
              onPressed: onBackToClient,
            ),
            const SizedBox(height: 12),
          ],
          BcButton(
            label: 'Se déconnecter',
            variant: BcButtonVariant.ghost,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String icon,
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              BcIcon(icon, size: 15, color: AppColors.sub),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.line),
      ],
    );
  }
}
