import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/logic/scan_parser.dart';
import '../../core/models/app_models.dart';

class ScanService {
  MobileScannerController buildScannerController(AppSettings settings) {
    return MobileScannerController(
      autoStart: true,
      facing: settings.preferFrontCamera ? CameraFacing.front : CameraFacing.back,
      detectionSpeed: settings.focusProfile == 'fast' ? DetectionSpeed.unrestricted : DetectionSpeed.normal,
      autoZoom: settings.autoZoom,
      formats: const <BarcodeFormat>[],
      torchEnabled: false,
      initialZoom: settings.focusProfile == 'macro' ? 0.2 : null,
    );
  }

  Future<Barcode?> analyzeImageFromGallery({
    required ImagePicker imagePicker,
    required MobileScannerController Function() controllerBuilder,
  }) async {
    final file = await imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final controller = controllerBuilder();
    try {
      final capture = await controller.analyzeImage(file.path);
      return capture?.barcodes.isNotEmpty == true ? capture!.barcodes.first : null;
    } finally {
      controller.dispose();
    }
  }

  (ScanInsight, List<ScanRecord>) processScan({
    required Barcode barcode,
    required List<ScanRecord> currentHistory,
    required int historyLimit,
  }) {
    final rawValue = barcode.rawValue?.trim() ?? '';
    final insight = describeScan(rawValue, barcode.format.name);
    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      rawValue: rawValue,
      codeType: insight.typeLabel,
      title: insight.title,
      scannedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final nextHistory = <ScanRecord>[record, ...currentHistory.where((item) => item.rawValue != rawValue)]
        .take(historyLimit)
        .toList();
    return (insight, nextHistory);
  }
}
