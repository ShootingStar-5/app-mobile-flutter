import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication_data.dart';

class MedicationExtractService {
  // TODO: 실제 서버 IP로 변경하세요
  // 에뮬레이터: 10.0.2.2:8000
  // 실제 기기: 컴퓨터의 로컬 IP (예: 192.168.x.x:8000)
  static const String baseUrl =
      'https://app-backend-fastapi-h7bsa9aucfdfeuhk.westus3-01.azurewebsites.net/'; //'http://172.16.30.30:8000';

  /// 음성 파일에서 약 정보 추출
  Future<MedicationExtractResult> extractFromVoice(String wavFilePath) async {
    try {
      final uri = Uri.parse('${baseUrl}api/v1/stt/extract');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('audio', wavFilePath),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var json = jsonDecode(responseBody);

      if (json['success'] == true && json['data'] != null) {
        return MedicationExtractResult(
          success: true,
          sttText: json['stt_text'] ?? '',
          data: MedicationData.fromJson(json['data']),
          message: json['message'] ?? '성공',
        );
      } else {
        return MedicationExtractResult(
          success: false,
          sttText: json['stt_text'] ?? '',
          data: null,
          message: json['message'] ?? '추출 실패',
        );
      }
    } catch (e) {
      return MedicationExtractResult(
        success: false,
        sttText: '',
        data: null,
        message: '서버 연결 실패: $e',
      );
    }
  }

  /// 텍스트에서 약 정보 추출 (테스트용)
  Future<MedicationExtractResult> extractFromText(String text) async {
    try {
      final uri = Uri.parse('${baseUrl}api/v1/stt/extract-text');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      var json = jsonDecode(response.body);

      if (json['success'] == true && json['data'] != null) {
        return MedicationExtractResult(
          success: true,
          sttText: json['input_text'] ?? text,
          data: MedicationData.fromJson(json['data']),
          message: json['message'] ?? '성공',
        );
      } else {
        return MedicationExtractResult(
          success: false,
          sttText: text,
          data: null,
          message: json['message'] ?? '추출 실패',
        );
      }
    } catch (e) {
      return MedicationExtractResult(
        success: false,
        sttText: text,
        data: null,
        message: '서버 연결 실패: $e',
      );
    }
  }

  /// 서버 상태 확인
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('${baseUrl}api/v1/stt/health');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class MedicationExtractResult {
  final bool success;
  final String sttText;
  final MedicationData? data;
  final String message;

  MedicationExtractResult({
    required this.success,
    required this.sttText,
    this.data,
    required this.message,
  });
}
