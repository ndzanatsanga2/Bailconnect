import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_logo.dart';
import 'admin_dashboard_tab.dart';
import 'admin_invitations_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';

const _tabs = [
  ('chart', 'Dashboard'),
  ('users', 'Utilisateurs'),
  ('inbox', 'Amorçage & invitations'),
  ('flag', 'Signalements'),
];

/// Back-office admin — section web de l'app Flutter, même design system que
/// le reste (fidèle au wireframe Admin, section 8). Django Admin reste en
/// secours technique interne mais n'est plus l'interface montrée.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final bodies = const [
      AdminDashboardTab(),
      AdminUsersTab(),
      AdminInvitationsTab(),
      AdminReportsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 240,
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BcLogoLockup(markSize: 26, fontSize: 15, textColor: Colors.white),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text('Admin', style: TextStyle(color: Color(0xFF9DB8AC), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < _tabs.length; i++) _navItem(i),
              ],
            ),
          ),
          Expanded(child: bodies[_index]),
        ],
      ),
    );
  }

  Widget _navItem(int index) {
    final active = index == _index;
    final (icon, label) = _tabs[index];
    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: active ? AppColors.green : Colors.transparent, borderRadius: BorderRadius.circular(11)),
        child: Row(
          children: [
            BcIcon(icon, size: 18, color: active ? Colors.white : const Color(0xFF9DB8AC)),
            const SizedBox(width: 11),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF9DB8AC)))),
          ],
        ),
      ),
    );
  }
}
