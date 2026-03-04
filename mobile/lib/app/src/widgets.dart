part of '../qrcodet_app.dart';

class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.runtimeMessage});

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
          Text('QRCodet', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: theme.light.withValues(alpha: 0.85), letterSpacing: 1.6)),
          const SizedBox(height: 6),
          Text('QR & Barcode Studio', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: theme.light, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(runtimeMessage.isEmpty ? 'Create, scan, save, and revisit every code from one place.' : runtimeMessage, style: TextStyle(color: theme.light.withValues(alpha: 0.82))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.kicker, required this.title});

  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(kicker.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.6)),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

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
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dark, width: 2), color: theme.light),
          child: Column(children: <Widget>[Text(header, style: TextStyle(color: theme.dark, fontWeight: FontWeight.w700)), const SizedBox(height: 8), child, const SizedBox(height: 8), Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.7)))]),
        );
      case 'ticket':
        return Container(
          decoration: BoxDecoration(color: theme.light, borderRadius: BorderRadius.circular(24)),
          child: Column(children: <Widget>[Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.dark, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Text(header, textAlign: TextAlign.center, style: TextStyle(color: theme.light))), Padding(padding: const EdgeInsets.all(12), child: child), Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.7))))]),
        );
      case 'badge':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.dark, borderRadius: BorderRadius.circular(28)),
          child: Column(children: <Widget>[Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(999)), child: Text(header, style: TextStyle(color: theme.light, fontWeight: FontWeight.w700))), const SizedBox(height: 12), child, if (metaLine.isNotEmpty) ...<Widget>[const SizedBox(height: 10), Text(metaLine, style: TextStyle(color: theme.light))], const SizedBox(height: 6), Text(footer, style: TextStyle(color: theme.light.withValues(alpha: 0.72)))]),
        );
      case 'poster':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.light, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dark, width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(header, style: TextStyle(color: theme.dark, fontSize: 24, fontWeight: FontWeight.w700)), Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.68))), const SizedBox(height: 12), child]),
        );
      default:
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: theme.light),
          child: Column(children: <Widget>[Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.dark, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Text(header, textAlign: TextAlign.center, style: TextStyle(color: theme.light, fontWeight: FontWeight.w700))), Padding(padding: const EdgeInsets.all(12), child: child), Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(footer, style: TextStyle(color: theme.dark.withValues(alpha: 0.75))))]),
        );
    }
  }
}
