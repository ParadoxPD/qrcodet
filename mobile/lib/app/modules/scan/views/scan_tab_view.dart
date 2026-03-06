import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/models/app_models.dart';
import '../../../views/widgets/app_widgets.dart';

class ScanTabView extends StatefulWidget {
  const ScanTabView({
    super.key,
    required this.controllerBuilder,
    required this.onDetect,
    required this.onAnalyzeImage,
    required this.hapticsEnabled,
    required this.insight,
    required this.history,
    required this.dateFormat,
    required this.onRestoreHistory,
  });

  final MobileScannerController Function() controllerBuilder;
  final Future<void> Function(Barcode barcode) onDetect;
  final Future<void> Function() onAnalyzeImage;
  final bool hapticsEnabled;
  final ScanInsight? insight;
  final List<ScanRecord> history;
  final DateFormat dateFormat;
  final ValueChanged<ScanRecord> onRestoreHistory;

  @override
  State<ScanTabView> createState() => _ScanTabViewState();
}

class _ScanTabViewState extends State<ScanTabView> {
  late MobileScannerController _controller;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultSectionKey = GlobalKey();
  final FocusNode _resultFocusNode = FocusNode();
  bool _handling = false;
  bool _torchOn = false;
  bool _scannerPaused = false;

  ScrollPhysics get _scrollPhysics {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
      default:
        return const ClampingScrollPhysics();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controllerBuilder();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _scrollController.dispose();
    _resultFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScanTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPayload = oldWidget.insight?.payload ?? '';
    final nextPayload = widget.insight?.payload ?? '';
    if (nextPayload.isNotEmpty && oldPayload != nextPayload) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToResultSection());
    }
  }

  void _scrollToResultSection() {
    final targetContext = _resultSectionKey.currentContext;
    if (targetContext == null || !_scrollController.hasClients) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
    _resultFocusNode.requestFocus();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_handling || _scannerPaused || capture.barcodes.isEmpty) return;
    final first = capture.barcodes.first;
    setState(() {
      _handling = true;
      _scannerPaused = true;
    });
    try {
      if (widget.hapticsEnabled) {
        await HapticFeedback.vibrate();
      }
      await _controller.stop();
      await widget.onDetect(first);
    } finally {
      if (mounted) {
        setState(() {
          _handling = false;
        });
      }
    }
  }

  Future<void> _handleUploadImage() async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _scannerPaused = true;
    });
    try {
      await _controller.stop();
      await widget.onAnalyzeImage();
    } finally {
      if (mounted) {
        setState(() {
          _handling = false;
        });
      }
    }
  }

  Future<void> _resumeScanner() async {
    await _controller.start();
    if (!mounted) return;
    setState(() {
      _scannerPaused = false;
      _handling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    return ListView(
      controller: _scrollController,
      physics: _scrollPhysics,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppSectionTitle(kicker: 'Realtime', title: 'Scan from the camera or an image'),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _handleCapture,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await _controller.switchCamera();
                        },
                        icon: const Icon(Icons.cameraswitch_outlined),
                        label: const Text('Switch Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _controller.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                        icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                        label: Text(_torchOn ? 'Torch On' : 'Torch Off'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _handleUploadImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Upload Image'),
                ),
                if (_scannerPaused) ...<Widget>[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _resumeScanner,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume Scanner'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          key: _resultSectionKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Focus(
              focusNode: _resultFocusNode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppSectionTitle(kicker: 'Result', title: 'Detected type, fields, and payload'),
                  const SizedBox(height: 12),
                  AppInfoTile(label: 'Detected type', value: insight?.typeLabel ?? 'Nothing scanned yet.'),
                  const SizedBox(height: 8),
                  AppInfoTile(label: 'Summary', value: insight?.title ?? 'Awaiting a scan'),
                  const SizedBox(height: 12),
                  Text('Fields', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (insight == null || insight.fields.isEmpty)
                    const Text('Structured fields appear here when the payload is recognized.')
                  else
                    ...insight.fields.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppInfoTile(label: item.label, value: item.value),
                        )),
                  const SizedBox(height: 12),
                  Text('Useful info', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (insight == null)
                    const Text('Scan a code to view context-aware hints.')
                  else
                    ...insight.usefulInfo.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppInfoTile(label: item.label, value: item.value),
                        )),
                  const SizedBox(height: 12),
                  Text('Raw payload', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SelectableText(
                    insight?.payload ?? '—',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSectionTitle(kicker: 'History', title: 'Recent scans (${widget.history.length})'),
                const SizedBox(height: 12),
                if (widget.history.isEmpty)
                  const Text('No scans yet.')
                else
                  ...widget.history.take(20).map(
                        (record) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(record.title),
                          subtitle: Text('${record.codeType} • ${widget.dateFormat.format(DateTime.fromMillisecondsSinceEpoch(record.scannedAt))}'),
                          trailing: IconButton(
                            onPressed: () => widget.onRestoreHistory(record),
                            icon: const Icon(Icons.history_rounded),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
