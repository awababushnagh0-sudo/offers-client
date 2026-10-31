import 'package:flutter/widgets.dart';

import '../icon/s_icon.dart';
import '../illustration/s_illustration_renderer.dart';

@immutable
class ProfileHeaderSpec {
  const ProfileHeaderSpec({
    required this.title,
    required this.subtitle,
    required this.role,
    required this.phone,
    required this.imageUrl,
  });

  final String title;
  final String? subtitle;
  final ProfileRole? role;
  final String? phone;
  final String? imageUrl;
}

/// Who the person is here, as a small tag beside their name.
@immutable
class ProfileRole {
  const ProfileRole({
    required this.label,
    required this.icon,
    this.lead = false,
  });

  final String label;
  final SIcons icon;

  /// The one in charge (a store's owner): the tag is the brand's green,
  /// with a sparkle; the others' is a quiet gray.
  final bool lead;
}

/// One card in [ProfileRenderer.shortcuts].
@immutable
class Shortcut {
  const Shortcut({
    required this.illustration,
    required this.label,
    required this.onTap,
    this.hint,
  });

  final Illustration illustration;
  final String label;

  /// What's inside, under [label].
  final String? hint;
  final VoidCallback onTap;
}

abstract interface class ProfileRenderer {
  Widget header(BuildContext context, ProfileHeaderSpec spec);

  Widget shortcuts(BuildContext context, List<Shortcut> shortcuts);
}
