import 'package:flutter/material.dart';

import '../../data/messaging_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_icon.dart';

/// Liste des conversations — partagée entre l'onglet Messages client et
/// l'onglet Messages bailleur (même présentation des deux côtés).
class ConversationsList extends StatelessWidget {
  final List<ConversationSummary> conversations;
  final ValueChanged<ConversationSummary> onOpen;

  const ConversationsList({
    super.key,
    required this.conversations,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BcIcon('chat', size: 40, color: AppColors.sub),
              const SizedBox(height: 14),
              const Text(
                'Aucune conversation pour l\'instant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Les échanges avec les annonceurs ou les clients apparaîtront ici.',
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
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = conversations[index];
        final unread = c.unreadCount > 0;
        return InkWell(
          onTap: () => onOpen(c),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unread ? AppColors.greenLight : AppColors.paper,
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
                        c.peerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.listingTitle,
                        style: const TextStyle(
                          color: AppColors.sub,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.lastMessage ?? 'Aucun message pour l\'instant.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread ? AppColors.ink : AppColors.sub,
                          fontSize: 12.5,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${c.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
