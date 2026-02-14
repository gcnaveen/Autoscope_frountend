import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:url_launcher/url_launcher.dart';

class SampleReportPage extends StatefulWidget {
  const SampleReportPage({super.key});

  @override
  State<SampleReportPage> createState() => _SampleReportPageState();
}

class _SampleReportPageState extends State<SampleReportPage> {
  static const _assetPath = 'assets/pdfs/sample_report.pdf';

  Uint8List? _bytes;
  String? _err;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final data = await rootBundle.load(_assetPath);
      setState(() {
        _bytes = data.buffer.asUint8List();
      });
    } catch (e) {
      setState(() => _err = e.toString());
    }
  }

  Future<void> _openInNewTabWeb() async {
    // For WEB: we open a "data:" url in a new tab
    // (works without adding extra packages)
    if (_bytes == null) return;
    final uri = Uri.dataFromBytes(_bytes!, mimeType: 'application/pdf');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Report'),
        actions: [
          if (kIsWeb)
            IconButton(
              tooltip: 'Open in new tab',
              onPressed: _bytes == null ? null : _openInNewTabWeb,
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (_err != null) {
            return Center(child: Text('Failed to load PDF: $_err'));
          }
          if (_bytes == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // WEB: show hint + open button (best UX)
          if (kIsWeb) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 42),
                        const SizedBox(height: 12),
                        const Text(
                          'Sample Report PDF',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Click below to open the PDF in a new tab.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _openInNewTabWeb,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open PDF'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Mobile/Desktop (non-web):
          // easiest is also open externally (works on Windows too)
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 42),
                      const SizedBox(height: 12),
                      const Text(
                        'Sample Report PDF',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click below to open the PDF.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.dataFromBytes(_bytes!, mimeType: 'application/pdf');
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
