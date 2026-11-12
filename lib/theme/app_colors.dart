import 'package:flutter/material.dart';

/// Semantic color tokens for the Medical Teal & Soft Slate theme.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF0E7C86);
  static const primaryDark = Color(0xFF095860);
  static const primaryLight = Color(0xFF149CA8);
  static const primarySoft = Color(0xFFE6F4F5);

  // Secondary / Clinical Accent
  static const secondary = Color(0xFF0284C7);
  static const secondarySoft = Color(0xFFE0F2FE);

  // Surfaces & Borders
  static const scaffoldBg = Color(0xFFF3F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);

  // Typography
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  // Semantic Status Pairs (Background + Foreground)
  static const successBg = Color(0xFFECFDF5);
  static const successFg = Color(0xFF059669);

  static const warningBg = Color(0xFFFFFBEB);
  static const warningFg = Color(0xFFD97706);

  static const infoBg = Color(0xFFEFF6FF);
  static const infoFg = Color(0xFF2563EB);

  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerFg = Color(0xFFDC2626);

  static const neutralBg = Color(0xFFF1F5F9);
  static const neutralFg = Color(0xFF475569);
}

