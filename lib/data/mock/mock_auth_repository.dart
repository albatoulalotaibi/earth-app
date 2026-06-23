import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Mock implementation of [AuthRepository] for offline development.
///
/// Replace this with a real HTTP-based implementation when the backend
/// team delivers their API.
class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  UserModel? _pendingBeneficiary;

  @override
  Future<UserModel> login({
    required String nationalId,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Always succeed with a dummy user for now
    _currentUser = UserModel(
      id: '1',
      firstName: 'Sundus',
      lastName: 'Ahmed',
      email: 'sundus@example.com',
      phone: '+966501234567',
      nationalId: nationalId,
      accountType: AccountType.normal,
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = UserModel(
      id: '2',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      nationalId: nationalId,
      accountType: AccountType.normal,
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> registerBeneficiary({
    required String firstName,
    required String lastName,
    required String nationalId,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Store as pending – not yet active until access code is verified
    _pendingBeneficiary = UserModel(
      id: '3',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      nationalId: nationalId,
      accountType: AccountType.beneficiary,
    );
    return _pendingBeneficiary!;
  }

  @override
  Future<UserModel> verifyAccessCode({
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // In mock mode, any code is valid
    if (_pendingBeneficiary != null) {
      _currentUser = _pendingBeneficiary;
      _pendingBeneficiary = null;
    } else {
      _currentUser = UserModel(
        id: '3',
        firstName: 'Beneficiary',
        lastName: 'User',
        email: 'beneficiary@example.com',
        phone: '+966500000000',
        nationalId: '0000000000',
        accountType: AccountType.beneficiary,
      );
    }
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _pendingBeneficiary = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }
}
