import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'box_painter.dart';
import 'models.dart';

/// One analyzed image: the bytes + the backend result.
class Frame {
  final Uint8List bytes;
  final DetectResult result;
  Frame(this.bytes, this.result);
}

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});
  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  // Live backend (Render free tier). Editable in-app via the URL field.
  static const _defaultUrl = 'https://yolo-model-detector.onrender.com';

  late ApiService _api;
  final _picker = ImagePicker();
  final _urlCtrl = TextEditingController();

  Frame? _frame;
  bool _busy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _api = ApiService(_defaultUrl);
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('base_url') ?? _defaultUrl;
    setState(() {
      _urlCtrl.text = saved;
      _api.baseUrl = saved;
    });
  }

  Future<void> _saveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = _urlCtrl.text.trim();
    await prefs.setString('base_url', url);
    _api.baseUrl = url;
    setState(() => _status = 'Checking backend…');
    final ok = await _api.health();
    setState(() => _status = ok ? 'Backend reachable ✓' : 'Backend NOT reachable ✗');
  }

  Future<void> _runOnImage(XFile? file) async {
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _busy = true;
      _status = 'Detecting… (first call may take ~50s while the server wakes)';
    });
    try {
      final res = await _api.detect(bytes, filename: file.name);
      setState(() {
        _frame = Frame(bytes, res);
        _status = _summary(res);
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  String _summary(DetectResult r) {
    final found = r.detections.map((d) => d.label).toSet().toList()..sort();
    return 'Found: ${found.isEmpty ? "nothing" : found.join(", ")}  '
        '· ${r.totalMs.toStringAsFixed(0)}ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tri-Model Detector')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _urlBar(),
            const SizedBox(height: 10),
            _actionButtons(),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_status, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            if (_frame != null) _imageWithBoxes(_frame!),
            if (_frame != null) _resultsPanel(_frame!.result),
          ],
        ),
      ),
    );
  }

  Widget _urlBar() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _saveUrl, child: const Text('Save')),
        ],
      );

  Widget _actionButtons() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () async =>
                    _runOnImage(await _picker.pickImage(source: ImageSource.camera)),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () async =>
                    _runOnImage(await _picker.pickImage(source: ImageSource.gallery)),
            icon: const Icon(Icons.image),
            label: const Text('Pick Image'),
          ),
        ],
      );

  Widget _imageWithBoxes(Frame frame) {
    final r = frame.result;
    final aspect = r.imageHeight == 0 ? 1.0 : r.imageWidth / r.imageHeight;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
      child: AspectRatio(
        aspectRatio: aspect == 0 ? 1 : aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(frame.bytes, fit: BoxFit.fill),
            CustomPaint(
              painter: DetectionPainter(r.detections, r.imageWidth, r.imageHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsPanel(DetectResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text('Model latency', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: r.perModel.entries.map((e) {
            final v = e.value as Map;
            final ms = v['ms'];
            final avail = v['available'] == true;
            return Chip(
              label: Text(avail
                  ? '${e.key}: ${ms ?? "-"}ms (${v['count']})'
                  : '${e.key}: off'),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text('Detections', style: TextStyle(fontWeight: FontWeight.bold)),
        ...r.detections.map((d) => ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: Color(kLabelColors[d.label] ?? 0xFF00E5FF),
                radius: 10,
              ),
              title: Text('${d.label}  ${(d.confidence * 100).toStringAsFixed(1)}%'),
              subtitle: Text('from ${d.sourceModel}'),
            )),
        if (r.detections.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('No objects detected.'),
          ),
      ],
    );
  }
}
