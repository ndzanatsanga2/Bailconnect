import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_chip.dart';

const _roles = [
  (null, 'Tous'),
  ('locataire', 'Locataires'),
  ('annonceur', 'Annonceurs'),
  ('admin', 'Admins'),
];

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _repository = AdminRepository(ApiClient());
  String? _role;
  late Future<List<AdminUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.users(role: _role);
  }

  void _setRole(String? role) {
    setState(() {
      _role = role;
      _future = _repository.users(role: _role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Utilisateurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: [
            for (final r in _roles) BcChip(label: r.$2, selected: _role == r.$1, onTap: () => _setRole(r.$1)),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
              child: FutureBuilder<List<AdminUser>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Center(child: Text('Aucun utilisateur.', style: TextStyle(color: AppColors.sub)));
                  }
                  return SingleChildScrollView(
                    child: Table(
                      columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.2)},
                      children: [
                        _headerRow(),
                        for (final user in users) _row(user),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    const style = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.sub, letterSpacing: 0.4);
    Widget cell(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), child: Text(text.toUpperCase(), style: style));
    return TableRow(children: [cell('Nom'), cell('Contact'), cell('Rôle')]);
  }

  TableRow _row(AdminUser user) {
    Widget cell(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: DefaultTextStyle(style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink), child: child),
        );
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      children: [
        cell(Text(user.fullName.isEmpty ? '—' : user.fullName)),
        cell(Text(user.email ?? user.phoneNumber ?? '—')),
        cell(Text(user.role)),
      ],
    );
  }
}
