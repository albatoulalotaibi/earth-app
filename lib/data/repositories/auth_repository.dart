import '../models/user_model.dart';

/// Contract for authentication operations.
///
/// The backend team only needs to create a class that `implements`
/// this interface. The UI code will not change at all.
abstract class AuthRepository {
  /// Authenticate with national ID and password.
  /// Returns the logged-in [UserModel] on success.
  Future<UserModel> login({
    required String nationalId,
    required String password,
  });

  /// Register a new normal user account.
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  });

  /// Register a new beneficiary account.
  /// Returns a [UserModel] but the account is not yet active,
  /// the user must verify via [verifyAccessCode] first.
  Future<UserModel> registerBeneficiary({
    required String firstName,
    required String lastName,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  });

  /// Verify the access code sent to the beneficiary.
  /// Returns the activated [UserModel] on success.
  Future<UserModel> verifyAccessCode({
    required String code,
  });

  /// Sign the current user out.
  Future<void> logout();

  /// Get the currently authenticated user, or `null` if not logged in.
  Future<UserModel?> getCurrentUser();
}
