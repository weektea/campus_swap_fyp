class UserSession {
  static final UserSession _instance = UserSession._internal();
  
  factory UserSession() {
    return _instance;
  }
  
  UserSession._internal();

  String? userId;
  String? email;
  String? username;
  String? fullName;
  String? token;
  String? avatarUrl;
  String? role;

  final List<String> sessionInteractions = [];

  bool get isLoggedIn => userId != null && token != null;

  void addSessionInteraction(String productId) {
    if (!sessionInteractions.contains(productId)) {
      sessionInteractions.add(productId);
    }
  }

  void clear() {
    userId = null;
    email = null;
    username = null;
    fullName = null;
    token = null;
    avatarUrl = null;
    role = null;
    sessionInteractions.clear();
  }
}
