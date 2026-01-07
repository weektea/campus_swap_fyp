class UserSession {
  static final UserSession _instance = UserSession._internal();
  
  factory UserSession() {
    return _instance;
  }
  
  UserSession._internal();

  String? userId;
  String? email;
  String? fullName;
  String? token;
  String? avatarUrl;

  bool get isLoggedIn => userId != null && token != null;

  void clear() {
    userId = null;
    email = null;
    fullName = null;
    token = null;
    avatarUrl = null;
  }
}
