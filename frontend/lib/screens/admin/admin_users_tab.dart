import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_data_table.dart';

const _roles = [
  (null, 'Tous'),
  ('locataire', 'Locataires'),
  ('annonceur', 'Annonceurs'),
  ('admin', 'Admins'),
];

const _roleLabels = {
  'locataire': 'Locataire',
  'annonceur': 'Annonceur',
  'admin': 'Admin',
};

(Color, Color) _roleColors(String role) => switch (role) {
  'admin' => (AppColors.amberLight, AppColors.amber),
  'annonceur' => (AppColors.greenLight, AppColors.greenDark),
  _ => (AppColors.line, AppColors.sub),
};

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _repository = AdminRepository(ApiClient());
  String? _role;
  String? _search;
  String _ordering = '-date_joined';
  int _page = 1;
  bool _loading = true;
  AdminPage<AdminUser> _result = const AdminPage(items: [], count: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.usersPage(
      role: _role,
      search: _search,
      ordering: _ordering,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _setRole(String? role) {
    setState(() {
      _role = role;
      _page = 1;
    });
    _load();
  }

  void _setSearch(String value) {
    setState(() {
      _search = value.isEmpty ? null : value;
      _page = 1;
    });
    _load();
  }

  void _setOrdering(String key) {
    setState(() {
      _ordering = _ordering == key ? '-$key' : key;
      _page = 1;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Utilisateurs',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Comptes locataires, annonceurs et admins',
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 22),
          BcDataTable<AdminUser>(
            title: 'Utilisateurs (${_result.count})',
            loading: _loading,
            emptyLabel: 'Aucun utilisateur pour ce filtre.',
            searchHint: 'Nom, email, téléphone…',
            onSearchChanged: _setSearch,
            sortKey: _ordering.replaceFirst('-', ''),
            sortAscending: !_ordering.startsWith('-'),
            onSortChanged: _setOrdering,
            filters: [
              for (final r in _roles)
                BcChip(
                  label: r.$2,
                  selected: _role == r.$1,
                  onTap: () => _setRole(r.$1),
                ),
            ],
            columns: const [
              BcColumn('Nom', flex: 2, sortKey: 'full_name'),
              BcColumn('Contact', flex: 2),
              BcColumn('Rôle', flex: 1),
            ],
            rows: _result.items,
            page: _page,
            pageCount: (_result.count / 10).ceil().clamp(1, 999999),
            totalCount: _result.count,
            onPageChanged: (page) {
              setState(() => _page = page);
              _load();
            },
            cellsBuilder: (user) {
              final (bg, fg) = _roleColors(user.role);
              return [
                Text(
                  user.fullName.isEmpty ? '—' : user.fullName,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email ?? user.phoneNumber ?? '—',
                  overflow: TextOverflow.ellipsis,
                ),
                BcPill(
                  label: _roleLabels[user.role] ?? user.role,
                  background: bg,
                  foreground: fg,
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
