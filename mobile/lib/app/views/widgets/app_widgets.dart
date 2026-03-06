import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.theme, required this.runtimeMessage});

  final ThemeSpec theme;
  final String runtimeMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: <Color>[theme.dark, theme.accent]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'QRCodet',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: theme.light.withValues(alpha: 0.85),
                  letterSpacing: 1.6,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'QR & Barcode Studio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.light,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            runtimeMessage.isEmpty
                ? 'Create, scan, save, and revisit every code from one place.'
                : runtimeMessage,
            style: TextStyle(color: theme.light.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({super.key, required this.kicker, required this.title});

  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          kicker.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.6),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class AppInfoTile extends StatelessWidget {
  const AppInfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class CodeFrameWidget extends StatelessWidget {
  const CodeFrameWidget({
    super.key,
    required this.frameId,
    required this.theme,
    required this.header,
    required this.footer,
    required this.metaLine,
    required this.child,
  });

  final String frameId;
  final ThemeSpec theme;
  final String header;
  final String footer;
  final String metaLine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dark.withValues(alpha: 0.2)),
      ),
      child: child,
    );

    switch (frameId) {
      case 'none':
        return base;
      case 'minimal':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dark, width: 2),
            color: theme.light,
          ),
          child: Column(
            children: <Widget>[
              Text(header, style: TextStyle(color: theme.dark, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              child,
              const SizedBox(height: 8),
              Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.7))),
            ],
          ),
        );
      case 'card':
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.light,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dark.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(colors: <Color>[Colors.transparent, theme.accent, Colors.transparent]),
                ),
              ),
              if (header.isNotEmpty) Text(header, style: TextStyle(color: theme.dark, fontWeight: FontWeight.w700)),
              child,
              if (metaLine.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(metaLine, style: TextStyle(color: theme.dark, fontWeight: FontWeight.w600)),
              ],
              if (footer.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.75))),
              ],
            ],
          ),
        );
      case 'ticket':
        return Container(
          decoration: BoxDecoration(color: theme.light, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.dark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Text(header, textAlign: TextAlign.center, style: TextStyle(color: theme.light)),
              ),
              Padding(padding: const EdgeInsets.all(12), child: child),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.7))),
              ),
            ],
          ),
        );
      case 'badge':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.dark, borderRadius: BorderRadius.circular(28)),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(999)),
                child: Text(header, style: TextStyle(color: theme.light, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              child,
              if (metaLine.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(metaLine, style: TextStyle(color: theme.light)),
              ],
              const SizedBox(height: 6),
              Text(footer, style: TextStyle(color: theme.light.withValues(alpha: 0.72))),
            ],
          ),
        );
      case 'poster':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.light,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dark, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(header, style: TextStyle(color: theme.dark, fontSize: 24, fontWeight: FontWeight.w700)),
              Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.68))),
              const SizedBox(height: 12),
              child,
            ],
          ),
        );
      case 'strip':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.light,
            border: Border.all(color: theme.dark.withValues(alpha: 0.85), width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.dark,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    header.isEmpty ? 'SCAN' : header.toUpperCase(),
                    style: TextStyle(color: theme.light, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      child,
                      if (footer.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.75))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 'ornate':
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.light,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.accent),
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Container(height: 1, color: theme.accent)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      header.isEmpty ? 'Elegant Scan' : header,
                      style: TextStyle(color: theme.dark, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: theme.accent)),
                ],
              ),
              const SizedBox(height: 10),
              child,
              if (footer.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.75))),
              ],
            ],
          ),
        );
      default:
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: theme.light),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.dark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Text(
                  header,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.light, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(padding: const EdgeInsets.all(12), child: child),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.75))),
              ),
            ],
          ),
        );
    }
  }
}
