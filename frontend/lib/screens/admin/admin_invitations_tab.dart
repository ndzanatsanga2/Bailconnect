import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_data_table.dart';

/// Amorçage & invitations — envoi manuel d'un lien unique de création de
/// compte à un annonceur non inscrit (spec point 8).
class AdminInvitationsTab extends StatefulWidget {
  const AdminInvitationsTab({super.key});

  @override
  State<AdminInvitationsTab> createState() => _AdminInvitationsTabState();
}

class _AdminInvitationsTabState extends State<AdminInvitationsTab> {
  final _repository = AdminRepository(ApiClient());
  final _phoneController = TextEditingController(text: '+237');
  final _listingIdController = TextEditingController();
  int _page = 1;
  bool _loading = true;
  bool _sending = false;
  AdminPage<AdminInvitation> _result = const AdminPage(items: [], count: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _listingIdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.invitationsPage(page: _page);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  Future<void> _send() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repository.sendInvitation(
        phoneNumber: _phoneController.text.trim(),
        listingId: int.tryParse(_listingIdController.text.trim()),
      );
      _phoneController.text = '+237';
      _listingIdController.clear();
      _page = 1;
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amorçage & invitations',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            "Publiez une annonce d'amorçage depuis l'outil de debug interne, puis envoyez le lien d'invitation ici pour que l'annonceur crée son compte.",
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvelle invitation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone annonceur',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _listingIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID annonce (optionnel)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    BcButton(
                      label: 'Envoyer',
                      icon: 'chat',
                      expand: false,
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BcDataTable<AdminInvitation>(
            title: 'Invitations envoyées (${_result.count})',
            loading: _loading,
            emptyLabel: 'Aucune invitation envoyée.',
            columns: const [
              BcColumn('Téléphone', flex: 2),
              BcColumn('Annonce', flex: 2),
              BcColumn('Statut', flex: 1),
            ],
            rows: _result.items,
            page: _page,
            pageCount: (_result.count / 10).ceil().clamp(1, 999999),
            totalCount: _result.count,
            onPageChanged: (page) {
              setState(() => _page = page);
              _load();
            },
            cellsBuilder: (invitation) {
              final used = invitation.usedAt != null;
              return [
                Text(invitation.phoneNumber),
                Text(
                  invitation.listingTitle ?? '—',
                  overflow: TextOverflow.ellipsis,
                ),
                BcPill(
                  label: used ? 'Utilisée' : 'En attente',
                  background: used
                      ? AppColors.greenLight
                      : AppColors.amberLight,
                  foreground: used ? AppColors.greenDark : AppColors.amber,
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
