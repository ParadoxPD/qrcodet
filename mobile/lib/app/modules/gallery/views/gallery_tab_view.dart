import 'dart:io';

import 'package:flutter/material.dart';

import '../../../providers/qrcodet_provider.dart';
import '../../../views/widgets/app_widgets.dart';

class GalleryTabView extends StatelessWidget {
  const GalleryTabView({super.key, required this.vm});

  final GalleryProvider vm;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: vm.saveDirectory().then((dir) async {
        if (!await dir.exists()) return <FileSystemEntity>[];
        final items = dir
            .listSync()
            .where((item) => item.path.toLowerCase().endsWith('.png'))
            .toList()
          ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        return items;
      }),
      builder: (context, snapshot) {
        final items = snapshot.data ?? <FileSystemEntity>[];
        return ListView(
          physics: vm.smoothScroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppSectionTitle(kicker: 'Gallery', title: 'Saved codes on this device'),
                    const SizedBox(height: 6),
                    Text(vm.settings.saveDirectoryPath, style: Theme.of(context).textTheme.bodySmall),
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
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(file, width: 56, height: 56, fit: BoxFit.cover),
                            ),
                            title: Text(file.uri.pathSegments.last),
                            subtitle: Text('Modified ${vm.dateFormat.format(stat.modified)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await file.delete();
                                vm.runSetState(() {});
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
