import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
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

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _openEditDialog(AdminUser user) async {
    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(
      text: user.phoneNumber ?? '',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result != true) return;
    try {
      await _repository.updateUser(
        user.id,
        fullName: nameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
      );
      _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _suspend(AdminUser user) async {
    try {
      await _repository.suspendUser(user.id);
      _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reactivate(AdminUser user) async {
    try {
      await _repository.reactivateUser(user.id);
      _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _archive(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver ce compte ?'),
        content: Text(
          '« ${user.fullName.isEmpty ? user.email ?? user.phoneNumber : user.fullName} » '
          'sera désactivé et archivé. Réactivable ensuite si besoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.archiveUser(user.id);
      _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _delete(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: Text(
          '« ${user.fullName.isEmpty ? user.email ?? user.phoneNumber : user.fullName} » '
          'et toutes ses données (annonces, messages) seront définitivement supprimés. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteUser(user.id);
      if (mounted) _load();
    } catch (error) {
      _showError(error);
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
              BcColumn('Statut', flex: 1),
              BcColumn('Actions', flex: 3),
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
              final (statusBg, statusFg, statusLabel) = user.isArchived
                  ? (AppColors.line, AppColors.sub, 'Archivé')
                  : user.isActive
                  ? (AppColors.greenLight, AppColors.greenDark, 'Actif')
                  : (AppColors.dangerLight, AppColors.danger, 'Suspendu');
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
                BcPill(label: statusLabel, background: statusBg, foreground: statusFg),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    BcButton(
                      label: 'Modifier',
                      icon: 'settings',
                      expand: false,
                      variant: BcButtonVariant.ghost,
                      onPressed: () => _openEditDialog(user),
                    ),
                    if (!user.isArchived)
                      user.isActive
                          ? BcButton(
                              label: 'Suspendre',
                              icon: 'close',
                              expand: false,
                              variant: BcButtonVariant.ghost,
                              onPressed: () => _suspend(user),
                            )
                          : BcButton(
                              label: 'Réactiver',
                              icon: 'check',
                              expand: false,
                              variant: BcButtonVariant.ghost,
                              onPressed: () => _reactivate(user),
                            ),
                    if (user.isArchived)
                      BcButton(
                        label: 'Réactiver',
                        icon: 'check',
                        expand: false,
                        variant: BcButtonVariant.ghost,
                        onPressed: () => _reactivate(user),
                      ),
                    if (!user.isArchived)
                      BcButton(
                        label: 'Archiver',
                        icon: 'bookmark',
                        expand: false,
                        variant: BcButtonVariant.ghost,
                        onPressed: () => _archive(user),
                      ),
                    BcButton(
                      label: 'Supprimer',
                      icon: 'close',
                      expand: false,
                      variant: BcButtonVariant.ghost,
                      onPressed: () => _delete(user),
                    ),
                  ],
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
