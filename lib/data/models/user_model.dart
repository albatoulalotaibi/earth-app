/// Account types in the Erth system.
enum AccountType { normal, beneficiary }

/// Data model representing a user in the Erth system.
///
/// Includes [fromJson] / [toJson] for seamless backend integration.
class UserModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? nationalId;
  final AccountType accountType;

  const UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.nationalId,
    this.accountType = AccountType.normal,
  });

  bool get isBeneficiary => accountType == AccountType.beneficiary;

  /// Create a [UserModel] from a JSON map (API response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      nationalId: json['national_id'] as String?,
      accountType: json['account_type'] == 'beneficiary'
          ? AccountType.beneficiary
          : AccountType.normal,
    );
  }

  /// Convert to a JSON map (API request body).
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      if (nationalId != null) 'national_id': nationalId,
      'account_type': accountType == AccountType.beneficiary ? 'beneficiary' : 'normal',
    };
  }

  /// Create a copy with some fields replaced.
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? nationalId,
    AccountType? accountType,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      accountType: accountType ?? this.accountType,
    );
  }
}

