// lib/data/jigle_api.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AskOut {
  final String answer;
  final List<dynamic> usedContext;
  AskOut({required this.answer, required this.usedContext});
  factory AskOut.fromJson(Map<String, dynamic> j) => AskOut(
    answer: j['answer'] ?? '',
    usedContext: (j['used_context'] as List?) ?? const [],
  );
}

class AgentCreateOut {
  final String status; // created | updated | need_more_info | conflict
  final Map<String, dynamic>? jig;
  final List<dynamic>? missingFields;
  final String? hint;
  AgentCreateOut({
    required this.status,
    this.jig,
    this.missingFields,
    this.hint,
  });
  factory AgentCreateOut.fromJson(Map<String, dynamic> j) => AgentCreateOut(
    status: j['status'],
    jig: j['jig'],
    missingFields: (j['missing_fields'] as List?) ?? const [],
    hint: j['hint'],
  );
}

String defaultBaseUrl() {
  // 에뮬레이터/웹 환경별 호스트 매핑
  if (kIsWeb) return 'http://172.17.8.52:8000';
  if (Platform.isAndroid) return 'http://172.17.8.52:8000'; // Android 에뮬레이터
  return 'http://172.17.8.52:8000'; // iOS 시뮬레이터/데스크톱
}

class JigleApi {
  final String baseUrl;
  final http.Client _client;
  JigleApi({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? defaultBaseUrl(),
      _client = client ?? http.Client();

  Future<AskOut> ask(String question, {int topK = 8}) async {
    final uri = Uri.parse('$baseUrl/agent/ask');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'top_k': topK}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractErr(res));
    }
    return AskOut.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<AgentCreateOut> createJigByNL(
    String message, {
    bool upsert = false,
  }) async {
    final uri = Uri.parse('$baseUrl/agent/jig/create');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'upsert': upsert}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractErr(res));
    }
    return AgentCreateOut.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  String _extractErr(http.Response r) {
    try {
      final m = jsonDecode(utf8.decode(r.bodyBytes));
      return m['detail']?.toString() ?? 'HTTP ${r.statusCode}';
    } catch (_) {
      return 'HTTP ${r.statusCode}';
    }
  }
}
