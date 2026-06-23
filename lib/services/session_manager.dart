import '../data/models/user_model.dart';

/// Simple session manager to hold the current user state.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  UserModel? _currentUser;

  String? token; 

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isBeneficiary =>
      _currentUser?.accountType == AccountType.beneficiary;

  /// Name shown in greeting headers.
  String get displayName => _currentUser?.firstName ?? 'User';

  void setUser(UserModel user, {String? userToken}) {
    _currentUser = user;
    if (userToken != null) {
      token = userToken;
    }
  }

  void clear() {
    _currentUser = null;
    token = null; 
  }
}