class LoginResponse {
  String? status;
  String? message;
  String? authorization;

  LoginResponse({this.status, this.message, this.authorization});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    authorization = json['Authorization'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['Authorization'] = authorization;
    return data;
  }
}
