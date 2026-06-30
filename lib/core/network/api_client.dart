import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_response.dart';

class ApiService {
  /* Singleton pattern - only one instance->using ._internal() */
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token; // to store the token 

  // Get stored token from memory 
  Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Save token to memory -> shared preferences 
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  //clear token on logout
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  //extracting current user's id from the token's payload
  String? getUserIdFromToken() {
    final token = _token;
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.decode(base64Url.normalize(payload));
      final decoded = utf8.decode(normalized);
      final jsonData = jsonDecode(decoded);
      
      return jsonData['userId']?.toString();
    } catch (e) {
      return 'Failed to extract user id';
    }
  }

  /*================= HTTPS METHODS =============*/
  // Get request
  Future<ApiResponse> get(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(endpoint),
        headers: ApiConstants.getHeaders(token),
      );
      return _handleResponse(response);
    } catch (err) {
      return _handleError(err);
    }
  }

  // post request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(endpoint),
        headers: ApiConstants.getHeaders(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (err) {
      return _handleError(err);
    }
  }

  // put request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse(endpoint),
        headers: ApiConstants.getHeaders(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (err) {
      return _handleError(err);
    }
  }

  // delete request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: ApiConstants.getHeaders(token),
      );
      return _handleResponse(response);
    } catch (err) {
      return _handleError(err);
    }
  }

  /* ============================= RESPONSE HANDLERS ====================================== */
  ApiResponse _handleError(dynamic error){
    // if(error is SocketException){
    //   return ApiResponse(status: -1, result: 'No internet connection, Please check your internet');
    // }
    if(error is http.ClientException){
      return ApiResponse(status: -1, result: 'No internet connction, please check your internet');
    }
    if (error is FormatException) {
      return ApiResponse(
        status: -1,
        result: 'Invalid response from the server.',
      );
    }
    return ApiResponse(
      status: -1,
      result: 'Something went wrong. Please try again.',
    );
  }

  // Handle http response
  ApiResponse _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return ApiResponse.fromJson(json);
    } catch (err) {
      return ApiResponse(
        status: response.statusCode,
        result: 'Server Error : ${response.statusCode}',
      );
    }
  }

  /* For file uploads along with json objects*/
  Future<ApiResponse> multipart(
    String endpoint,
    String filePath,
    String fileFieldName, {
    Map<String, String>? fields,
  }) async {
  try {
    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(endpoint),
    );
    final headers = ApiConstants.getHeaders(token);
    headers.remove('Content-Type'); 
    request.headers.addAll(headers);

    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

    final file = await http.MultipartFile.fromPath(
      fileFieldName,
      filePath,
      contentType: http.MediaType.parse(mimeType),
    );
    request.files.add(file);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final jsonData = jsonDecode(responseBody);

    return ApiResponse.fromJson(jsonData);
  } catch (err) {
    return _handleError(err); 
  }
}
}