import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';

const _reasonLabels = {
  'fausse_annonce': 'Fausse annonce',
  'deja_loue': 'Déjà loué',
  'contenu_inapproprie': 'Contenu inapproprié',
  'autre': 'Autre',
};

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _repository = AdminRepository(ApiClient());
  late Future<List<AdminReport>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.reports(status: 'ouvert');
  }

  Future<void> _resolve(int id, String status) async {
    await _repository.resolveReport(id, status);
    setState(() => _future = _repository.reports(status: 'ouvert'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Signalements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<AdminReport>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return const Center(child: Text('Aucun signalement ouvert.', style: TextStyle(color: AppColors.sub)));
                }
                return ListView.separated(
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(13)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report.listingTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_reasonLabels[report.reason] ?? report.reason} · signalé par ${report.reporterIdentifier}',
                                  style: const TextStyle(color: AppColors.sub, fontSize: 12),
                                ),
                                if (report.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(report.description, style: const TextStyle(fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          BcButton(label: 'Traité', icon: 'check', expand: false, onPressed: () => _resolve(report.id, 'traite')),
                          const SizedBox(width: 8),
                          BcButton(label: 'Rejeter', icon: 'close', expand: false, variant: BcButtonVariant.ghost, onPressed: () => _resolve(report.id, 'rejete')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
