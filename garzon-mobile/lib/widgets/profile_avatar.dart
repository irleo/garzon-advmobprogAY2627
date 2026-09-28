import 'dart:convert';

import 'package:flutter/material.dart';

const Map<String, IconData> profileIcons = <String, IconData>{
  'Knight': Icons.shield_rounded,
  'Champion': Icons.emoji_events_rounded,
  'Wizard': Icons.auto_fix_high_rounded,
  'Dragon': Icons.local_fire_department_rounded,
  'Royal': Icons.workspace_premium_rounded,
  'Explorer': Icons.explore_rounded,
  'Rocket': Icons.rocket_launch_rounded,
  'Gamer': Icons.sports_esports_rounded,
  'Ninja': Icons.bolt_rounded,
  'Guardian': Icons.security_rounded,
  'Star': Icons.star_rounded,
  'Scholar': Icons.school_rounded,
};

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.selection,
    required this.remoteImage,
    super.key,
  });
  final String? selection;
  final String remoteImage;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String? value = selection;
    Widget fallback() =>
        Icon(Icons.person_rounded, size: 64, color: colors.onPrimaryContainer);
    Widget content;
    if (value != null && value.startsWith('icon:')) {
      content = Icon(
        profileIcons[value.substring(5)] ?? Icons.person_rounded,
        size: 58,
        color: colors.onPrimaryContainer,
      );
    } else if (value != null && value.startsWith('photo:')) {
      try {
        content = Image.memory(
          base64Decode(value.substring(6)),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
      } on FormatException {
        content = fallback();
      }
    } else if (remoteImage.isNotEmpty) {
      content = Image.network(
        remoteImage,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else {
      content = fallback();
    }
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary, width: 3),
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(child: content),
    );
  }
}
