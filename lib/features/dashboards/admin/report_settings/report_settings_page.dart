import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_shell.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/top_snackbar.dart';

class ReportSettingsPage extends StatefulWidget {
  const ReportSettingsPage({super.key});

  @override
  State<ReportSettingsPage> createState() => _ReportSettingsPageState();
}

class _ReportSettingsPageState extends State<ReportSettingsPage> {
  bool _loading = true;
  bool _saving = false;
  final List<TextEditingController> _ctrls = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    reportSettingsService.clearCache();
    try {
      final points = await reportSettingsService.loadDisclaimer();
      if (!mounted) return;
      _resetControllers(points.isNotEmpty ? points : _kFallback);
    } catch (_) {
      if (!mounted) return;
      _resetControllers(_kFallback);
      showTopSnack(context, 'Could not load from server — showing defaults', variant: 'warning');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetControllers(List<String> points) {
    for (final c in _ctrls) c.dispose();
    _ctrls
      ..clear()
      ..addAll(points.map((p) => TextEditingController(text: p)));
    setState(() {});
  }

  void _addPoint() {
    setState(() => _ctrls.add(TextEditingController()));
  }

  void _removeAt(int i) {
    if (_ctrls.length <= 1) {
      showTopSnack(context, 'At least one disclaimer point is required', variant: 'warning');
      return;
    }
    final c = _ctrls.removeAt(i);
    c.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final points = _ctrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (points.isEmpty) {
      showTopSnack(context, 'Add at least one disclaimer point', variant: 'warning');
      return;
    }

    setState(() => _saving = true);
    try {
      await reportSettingsService.saveDisclaimer(points);
      if (mounted) showTopSnack(context, 'Disclaimer saved', variant: 'success');
    } catch (e) {
      if (mounted) showTopSnack(context, 'Save failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Report Settings',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
              children: [
                // ── Header ───────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          height: 44, width: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E5EFF).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description_outlined,
                              color: Color(0xFF1E5EFF)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Report Disclaimer',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 16)),
                              SizedBox(height: 4),
                              Text(
                                'These points appear at the end of every inspection report.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        if (_saving)
                          const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Disclaimer points ─────────────────────────────────────
                for (int i = 0; i < _ctrls.length; i++) ...[
                  _PointRow(
                    index: i,
                    controller: _ctrls[i],
                    onDelete: () => _removeAt(i),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Add point ─────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _addPoint,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Point'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.15)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Save ──────────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving…' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Individual point row ─────────────────────────────────────────────────────

class _PointRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final VoidCallback onDelete;

  const _PointRow({
    required this.index,
    required this.controller,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            minLines: 2,
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
            decoration: InputDecoration(
              hintText: 'Enter disclaimer point…',
              hintStyle:
                  const TextStyle(color: Colors.black38, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Remove point',
          icon: const Icon(Icons.delete_outline,
              size: 18, color: Colors.red),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }
}

// ─── Hardcoded fallback (used when API returns nothing) ───────────────────────

const _kFallback = [
  'This report reflects the visible condition of the vehicle only at the time and date of inspection.',
  'The inspection is provided solely as an aid for evaluating the vehicle\'s general condition and does not constitute a warranty, guarantee, or recommendation to buy or sell the vehicle.',
  'The inspection conducted by Auto Scope is limited strictly to the items listed in this report and is visual, non-invasive, and non-mechanical in nature.',
  'No dismantling, disassembly, or internal examination of components has been carried out.',
  'The inspection does not include verification of service history, accident history, ownership records, recalls, mileage accuracy, or seller-provided specifications/features.',
  'Certain hidden, internal, or intermittent defects may not be detectable at the time of inspection despite standard inspection procedures being followed.',
  'Mechanical, electrical, and electronic components may fail at any time after inspection, and Auto Scope accepts no responsibility for issues arising thereafter.',
  'Auto Scope shall not be liable for repair costs, damages, losses, undiscovered defects, or differences between this report and future third-party assessments.',
  'This report is prepared exclusively for the client who ordered the inspection. Any third-party reliance on this report shall be entirely at their own risk.',
  'This report is issued strictly for informational purposes and should not be considered a warranty or guarantee of the vehicle\'s condition.',
];
