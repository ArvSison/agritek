import 'package:flutter/material.dart';

class NotificationBadgeIcon extends StatelessWidget {
  final IconData icon;
  final int unreadCount;

  const NotificationBadgeIcon({
    super.key,
    required this.icon,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final show = unreadCount > 0;
    final text = unreadCount > 9 ? '9+' : unreadCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (show)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

