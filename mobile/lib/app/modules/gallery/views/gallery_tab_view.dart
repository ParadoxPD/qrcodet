import 'dart:io';

import 'package:flutter/material.dart';

import '../../../providers/qrcodet_provider.dart';
import '../../../views/widgets/app_widgets.dart';

class GalleryTabView extends StatefulWidget {
  const GalleryTabView({super.key, required this.vm});

  final GalleryProvider vm;

  @override
  State<GalleryTabView> createState() => _GalleryTabViewState();
}

class _GalleryTabViewState extends State<GalleryTabView> {
  late Future<List<FileSystemEntity>> _itemsFuture;
  int _lastVersion = -1;

  @override
  void initState() {
    super.initState();
    _lastVersion = widget.vm.galleryVersion;
    _itemsFuture = widget.vm.loadGalleryEntities();
  }

  @override
  void didUpdateWidget(covariant GalleryTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final versionChanged = _lastVersion != widget.vm.galleryVersion;
    final pathChanged =
        oldWidget.vm.settings.saveDirectoryPath !=
        widget.vm.settings.saveDirectoryPath;
    if (!versionChanged && !pathChanged) {
      return;
    }
    _lastVersion = widget.vm.galleryVersion;
    _itemsFuture = widget.vm.loadGalleryEntities();
  }

  Future<void> _refreshItems() async {
    _lastVersion = widget.vm.galleryVersion;
    _itemsFuture = widget.vm.loadGalleryEntities();
  }

  Future<void> _showPreviewModal(File file) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(file, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                file.uri.pathSegments.last,
                style: Theme.of(sheetContext).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          widget.vm.openGalleryEntityInFiles(file.path),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Open in Files'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => widget.vm.shareGalleryEntity(file.path),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share PNG'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? <FileSystemEntity>[];
        return ListView(
          physics: widget.vm.smoothScroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppSectionTitle(
                      kicker: 'Gallery',
                      title: 'Saved codes on this device',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.vm.settings.saveDirectoryPath,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const Text('No saved QR or barcode images yet.')
                    else
                      ...items.map((entity) {
                        final file = File(entity.path);
                        final stat = file.statSync();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => _showPreviewModal(file),
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(file.uri.pathSegments.last),
                            subtitle: Text(
                              'Modified ${widget.vm.dateFormat.format(stat.modified)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await widget.vm.deleteGalleryEntity(file.path);
                                await _refreshItems();
                              },
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
