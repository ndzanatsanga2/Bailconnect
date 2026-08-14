import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_card.dart';
import '../../widgets/bc_kpi_card.dart';
import '../../widgets/bc_trend_chart.dart';

/// Vue d'ensemble — KPI et tendances de la plateforme, avec un aperçu de la
/// file de validation renvoyant vers l'onglet Annonces pour l'action complète.
class AdminDashboardTab extends StatefulWidget {
  final VoidCallback onViewPendingListings;

  const AdminDashboardTab({super.key, required this.onViewPendingListings});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _repository = AdminRepository(ApiClient());
  late Future<AdminDashboard> _dashboardFuture;
  late Future<List<AdminListing>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dashboardFuture = _repository.dashboard();
    _pendingFuture = _repository.pendingListingsPreview();
  }

  Future<void> _decide(int id, bool approve) async {
    if (approve) {
      await _repository.approveListing(id);
    } else {
      await _repository.rejectListing(id);
    }
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vue d'ensemble",
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Modération et activité de la plateforme',
            style: TextStyle(fontSize: 13, color: AppColors.sub),
          ),
          const SizedBox(height: 22),
          FutureBuilder<AdminDashboard>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              final d = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BcKpiCard(
                          value: '${d?.clientsCount ?? '—'}',
                          label: 'Clients',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BcKpiCard(
                          value: '${d?.annonceursCount ?? '—'}',
                          label: 'Annonceurs',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BcKpiCard(
                          value: '${d?.listingsPendingCount ?? '—'}',
                          label: 'Annonces à valider',
                          highlighted: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BcKpiCard(
                          value: '${d?.listingsPublishedCount ?? '—'}',
                          label: 'Annonces publiées',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BcKpiCard(
                          value: '${d?.reportsOpenCount ?? '—'}',
                          label: 'Signalements ouverts',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BcTrendChart(
                          title: 'Annonces publiées (14 derniers jours)',
                          points: (d?.listingsPublishedByDay ?? [])
                              .map(
                                (p) =>
                                    BcTrendPoint(date: p.date, count: p.count),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BcTrendChart(
                          title: 'Nouveaux comptes (14 derniers jours)',
                          points: (d?.signupsByDay ?? [])
                              .map(
                                (p) =>
                                    BcTrendPoint(date: p.date, count: p.count),
                              )
                              .toList(),
                          barColor: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          BcCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'File de validation des annonces',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    BcButton(
                      label: 'Voir toutes les annonces',
                      icon: 'grid',
                      expand: false,
                      variant: BcButtonVariant.ghost,
                      onPressed: widget.onViewPendingListings,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<AdminListing>>(
                  future: _pendingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final pending = snapshot.data ?? [];
                    if (pending.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Aucune annonce en attente.',
                          style: TextStyle(color: AppColors.sub),
                        ),
                      );
                    }
                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.4),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(1.8),
                      },
                      children: [
                        _headerRow(),
                        for (final listing in pending) _row(listing),
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
    const style = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppColors.sub,
      letterSpacing: 0.4,
    );
    Widget cell(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(text.toUpperCase(), style: style),
    );
    return TableRow(
      children: [
        cell('Annonce'),
        cell('Annonceur'),
        cell('Quartier'),
        cell('Loyer'),
        cell('Action'),
      ],
    );
  }

  TableRow _row(AdminListing listing) {
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        child: child,
      ),
    );
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      children: [
        cell(Text(listing.title)),
        cell(Text(listing.ownerDisplay)),
        cell(Text(listing.neighborhood)),
        cell(Text('${listing.rentAmount} F')),
        cell(
          Row(
            children: [
              BcButton(
                label: 'Valider',
                icon: 'check',
                expand: false,
                onPressed: () => _decide(listing.id, true),
              ),
              const SizedBox(width: 8),
              BcButton(
                label: 'Rejeter',
                icon: 'close',
                expand: false,
                variant: BcButtonVariant.ghost,
                onPressed: () => _decide(listing.id, false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
