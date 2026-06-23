import '../models/asset_model.dart';

/// Contract for asset operations.
///
/// The backend team only needs to create a class that `implements`
/// this interface. The UI code will not change at all.
abstract class AssetRepository {
  /// Get all assets for the current user.
  Future<List<AssetModel>> getAssets();

  /// Get assets filtered by category.
  Future<List<AssetModel>> getAssetsByCategory(AssetCategory category);

  /// Get a single asset by ID.
  Future<AssetModel?> getAssetById(String id);

  /// Search assets by name.
  Future<List<AssetModel>> searchAssets(String query);

  /// Delete an asset.
  Future<void> deleteAsset(String id);
}
