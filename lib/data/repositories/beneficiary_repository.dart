import '../models/beneficiary_model.dart';

/// Contract for beneficiary CRUD operations.
abstract class BeneficiaryRepository {
  /// Fetch all beneficiaries for the current user.
  Future<List<BeneficiaryModel>> getBeneficiaries();

  /// Add a new beneficiary. Returns the created beneficiary.
  Future<BeneficiaryModel> addBeneficiary(BeneficiaryModel beneficiary);

  /// Update an existing beneficiary.
  Future<BeneficiaryModel> updateBeneficiary(BeneficiaryModel beneficiary);

  /// Delete a beneficiary by its [id].
  Future<void> deleteBeneficiary(String id);
}
