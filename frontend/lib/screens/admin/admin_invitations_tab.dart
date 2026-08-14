import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';

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
  late Future<List<AdminInvitation>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.invitations();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _listingIdController.dispose();
    super.dispose();
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
      setState(() => _future = _repository.invitations());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amorçage & invitations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            "Publiez une annonce d'amorçage depuis Django Admin (outil interne), puis envoyez le lien d'invitation ici pour que l'annonceur crée son compte.",
            style: TextStyle(fontSize: 12.5, color: AppColors.sub),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouvelle invitation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Téléphone annonceur', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _listingIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ID annonce (optionnel)', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    BcButton(label: 'Envoyer', icon: 'chat', expand: false, onPressed: _sending ? null : _send),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Invitations envoyées', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                FutureBuilder<List<AdminInvitation>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final invitations = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.done && invitations.isEmpty) {
                      return const Text('Aucune invitation envoyée.', style: TextStyle(color: AppColors.sub));
                    }
                    return Table(
                      columnWidths: const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(1.6), 2: FlexColumnWidth(1)},
                      children: [
                        _headerRow(),
                        for (final invitation in invitations) _row(invitation),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    const style = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.sub, letterSpacing: 0.4);
    Widget cell(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text(text.toUpperCase(), style: style));
    return TableRow(children: [cell('Téléphone'), cell('Annonce'), cell('Statut')]);
  }

  TableRow _row(AdminInvitation invitation) {
    Widget cell(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: DefaultTextStyle(style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink), child: child),
        );
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      children: [
        cell(Text(invitation.phoneNumber)),
        cell(Text(invitation.listingTitle ?? '—')),
        cell(Text(invitation.usedAt != null ? 'Utilisée' : 'En attente')),
      ],
    );
  }
}
