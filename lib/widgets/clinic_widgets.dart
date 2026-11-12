import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/session.dart';
import '../theme/app_colors.dart';

/// Safely reads [Session] when a [Provider<Session>] ancestor exists.
Session? maybeSession(BuildContext context, {bool listen = true}) {
  try {
    return Provider.of<Session>(context, listen: listen);
  } on ProviderNotFoundException {
    return null;
  }
}

/// Semantic tone variants for [StatusBadge].
enum BadgeTone { primary, success, warning, info, danger, neutral }

/// Pill-shaped semantic status badge used across cards and headers.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.primary => (AppColors.primarySoft, AppColors.primaryDark),
      BadgeTone.success => (AppColors.successBg, AppColors.successFg),
      BadgeTone.warning => (AppColors.warningBg, AppColors.warningFg),
      BadgeTone.info => (AppColors.infoBg, AppColors.infoFg),
      BadgeTone.danger => (AppColors.dangerBg, AppColors.dangerFg),
      BadgeTone.neutral => (AppColors.neutralBg, AppColors.neutralFg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent section header with optional subtitle and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

/// Clean key-value display row for details and invoices.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    required this.value,
    this.icon,
    this.bold = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 15 : 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Centered empty-state panel with tinted icon badge and optional action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ),
  );
}

/// Centered error-state panel with parsed error text and retry button.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Thử lại',
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.dangerFg,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Inline alert banner for errors, hints, or disclaimers.
class ClinicBanner extends StatelessWidget {
  const ClinicBanner({
    required this.message,
    this.tone = BadgeTone.info,
    this.icon,
    this.trailing,
    super.key,
  });

  final String message;
  final BadgeTone tone;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, defaultIcon) = switch (tone) {
      BadgeTone.danger => (
        AppColors.dangerBg,
        AppColors.dangerFg,
        Icons.error_outline,
      ),
      BadgeTone.warning => (
        AppColors.warningBg,
        AppColors.warningFg,
        Icons.warning_amber_rounded,
      ),
      BadgeTone.success => (
        AppColors.successBg,
        AppColors.successFg,
        Icons.check_circle_outline,
      ),
      BadgeTone.primary => (
        AppColors.primarySoft,
        AppColors.primaryDark,
        Icons.info_outline,
      ),
      _ => (AppColors.infoBg, AppColors.infoFg, Icons.info_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Circular user/doctor avatar supporting relative `/uploads/...` paths and fallbacks.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    this.imagePath,
    this.name,
    this.radius = 22,
    this.fallbackIcon = Icons.person_outline,
    super.key,
  });

  final String? imagePath;
  final String? name;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final resolved = Api.instance.resolveUrl(imagePath);
    final initials = _initials(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      foregroundColor: AppColors.primaryDark,
      child: resolved == null
          ? _fallback(initials)
          : ClipOval(
              child: Image.network(
                resolved,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(initials),
              ),
            ),
    );
  }

  Widget _fallback(String? initials) {
    if (initials != null) {
      return Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      );
    }
    return Icon(fallbackIcon, size: radius, color: AppColors.primaryDark);
  }

  String? _initials(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Responsive KPI summary card used in Admin and Doctor dashboards.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = BadgeTone.primary,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (AppColors.successBg, AppColors.successFg),
      BadgeTone.warning => (AppColors.warningBg, AppColors.warningFg),
      BadgeTone.info => (AppColors.infoBg, AppColors.infoFg),
      BadgeTone.danger => (AppColors.dangerBg, AppColors.dangerFg),
      _ => (AppColors.primarySoft, AppColors.primaryDark),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Constrains page content cleanly across mobile, tablet, and desktop widths.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.maxWidth = 840,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
