import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
const _uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryUploader {
  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw const CloudinaryUploadException(
        'Chưa cấu hình Cloudinary. Chạy ứng dụng với CLOUDINARY_CLOUD_NAME và CLOUDINARY_UPLOAD_PRESET; xem README.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.https(
        'api.cloudinary.com',
        '/v1_1/$_cloudName/image/upload',
      ),
    )
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

    try {
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse).timeout(
            const Duration(seconds: 30),
          );
      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic> &&
                decoded['error'] is Map<String, dynamic>
            ? (decoded['error'] as Map<String, dynamic>)['message']
            : null;
        throw CloudinaryUploadException(
          message is String
              ? 'Cloudinary từ chối ảnh: $message'
              : 'Tải ảnh lên Cloudinary thất bại (HTTP ${response.statusCode}).',
        );
      }
      if (decoded is! Map<String, dynamic> || decoded['secure_url'] is! String) {
        throw const CloudinaryUploadException(
          'Cloudinary trả về dữ liệu không hợp lệ, không tìm thấy URL ảnh.',
        );
      }
      return decoded['secure_url'] as String;
    } on CloudinaryUploadException {
      rethrow;
    } on http.ClientException catch (error) {
      throw CloudinaryUploadException('Không kết nối được Cloudinary: $error');
    } on TimeoutException {
      throw const CloudinaryUploadException(
        'Tải ảnh lên Cloudinary quá thời gian. Hãy kiểm tra mạng và thử lại.',
      );
    } on FormatException {
      throw const CloudinaryUploadException(
        'Cloudinary trả về phản hồi không đọc được.',
      );
    }
  }
}
