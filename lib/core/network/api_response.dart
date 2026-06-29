class ApiResponse {
  final int status;
  final String result;
  final String? token;
  final dynamic data;

  ApiResponse({
    required this.status,
    required this.result,
    this.token,
    this.data,
  });

  // function to handle different response formats
  /* factory is like a constructor which doesnot always create a new instance  */
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    dynamic data = json['data'];
    if (data == null && json['users'] != null) {
      data = json['users'];
    } else if (data == null && json['friends'] != null) {
      data = json['friends'];
    } else if (data == null && json['requests'] != null) {
      data = json['requests'];
    } else if (data == null && json['user'] != null) {
      data = json['user'];
    } else if (data == null && json['messages'] != null) {
      data = json['messages'];
    } else if (data == null && json['chats'] != null) { 
      data = json['chats'];
    }
    return ApiResponse(
      status: json['status'] ?? 500,
      result: json['result'] ?? 'Unknown error',
      token: json['token'],
      data: data,
    );
  }

  // convert to json
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'result': result,
      'token': token,
      'data': data,
    };
  }

  // Getters
  bool get isSuccess => status >= 200 && status < 300;
  bool get isError => status >= 400;

  @override
  String toString() {
    return 'ApiResponse(status: $status, result: $result, token: $token, data: $data)';
  }

}