import '../models/beneficiary_model.dart';
import '../repositories/beneficiary_repository.dart';

/// Mock implementation of [BeneficiaryRepository] for offline development.
class MockBeneficiaryRepository implements BeneficiaryRepository {
  final List<BeneficiaryModel> _beneficiaries = [
    const BeneficiaryModel(
      id: '1',
      firstName: 'Sara',
      lastName: 'Mohammed',
      nationalId: '1111111111',
      phone: '+966509876543',
      email: 'sara@example.com',
      relationship: 'Daughter',
    ),
    const BeneficiaryModel(
      id: '2',
      firstName: 'Ahmed',
      lastName: 'Mohammed',
      nationalId: '2222222222',
      phone: '+966501112233',
      email: 'ahmed@example.com',
      relationship: 'Son',
    ),
    const BeneficiaryModel(
      id: '3',
      firstName: 'Fatima',
      lastName: 'Mohammed',
      nationalId: '3333333333',
      phone: '+966504445566',
      email: 'fatima@example.com',
      relationship: 'Wife',
    ),
    const BeneficiaryModel(
      id: '4',
      firstName: 'Khalid',
      lastName: 'Mohammed',
      nationalId: '4444444444',
      phone: '+966507778899',
      email: 'khaled@example.com',
      relationship: 'Brother',
    ),
  ];

  @override
  Future<List<BeneficiaryModel>> getBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_beneficiaries);
  }

  @override
  Future<BeneficiaryModel> addBeneficiary(BeneficiaryModel beneficiary) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newBeneficiary = beneficiary.copyWith(
      id: (_beneficiaries.length + 1).toString(),
    );
    _beneficiaries.add(newBeneficiary);
    return newBeneficiary;
  }

  @override
  Future<BeneficiaryModel> updateBeneficiary(
      BeneficiaryModel beneficiary) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _beneficiaries.indexWhere((b) => b.id == beneficiary.id);
    if (index != -1) {
      _beneficiaries[index] = beneficiary;
    }
    return beneficiary;
  }

  @override
  Future<void> deleteBeneficiary(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _beneficiaries.removeWhere((b) => b.id == id);
  }
}
