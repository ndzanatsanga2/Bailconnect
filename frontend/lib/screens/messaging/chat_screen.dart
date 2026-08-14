import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bc_mobile_frame.dart';
import 'chat_view.dart';

/// Écran de discussion plein écran — utilisé côté client (poussé en route
/// depuis l'onglet Messages ou une fiche bien). Côté bailleur, la discussion
/// est intégrée directement dans l'onglet Messages de son espace via
/// [ChatView] plutôt que cette route (voir AnnonceurWebDashboard/Mobile).
class ChatScreen extends StatelessWidget {
  final int conversationId;
  final String peerName;
  final String listingTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.listingTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BcMobileFrame(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: ChatView(
            conversationId: conversationId,
            peerName: peerName,
            listingTitle: listingTitle,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
