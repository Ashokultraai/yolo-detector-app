import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'models.dart';

/// Talks to the FastAPI backend.
///
/// For development point [baseUrl] at your ngrok URL (https://xxxx.ngrok-free.app).
/// For the release APK point it at your Hugging Face Space
/// (https://<user>-<space>.hf.space).
class ApiService {
  String baseUrl;
  ApiService(this.baseUrl);

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<bool> health() async {
    try {
      final r = await http.get(_u('/health')).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> models() async {
    final r = await http.get(_u('/models')).timeout(const Duration(seconds: 20));
    return (jsonDecode(r.body)['models'] as List);
  }

  /// Run detection on raw image bytes. Default = ensemble of all 3 models.
  Future<DetectResult> detect(
    Uint8List bytes, {
    String filename = 'frame.jpg',
    String mode = 'ensemble',
    String? model,
  }) async {
    var path = '/detect?mode=$mode';
    if (model != null) path += '&model=$model';
    final req = http.MultipartRequest('POST', _u(path))
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception('backend ${resp.statusCode}: ${resp.body}');
    }
    return DetectResult.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
