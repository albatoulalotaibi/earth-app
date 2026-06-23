/// Data model representing a beneficiary.
class BeneficiaryModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String nationalId;
  final String phone;
  final String email;
  final String relationship;

  const BeneficiaryModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalId,
    required this.phone,
    required this.email,
    required this.relationship,
  });

  String get fullName => '$firstName $lastName';

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      id: json['id'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      nationalId: json['national_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'national_id': nationalId,
      'phone': phone,
      'email': email,
      'relationship': relationship,
    };
  }

  BeneficiaryModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? nationalId,
    String? phone,
    String? email,
    String? relationship,
  }) {
    return BeneficiaryModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
    );
  }
}
