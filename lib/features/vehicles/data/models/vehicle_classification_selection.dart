import 'catalog_refs.dart';

/// The identity being edited, independent of labels that may be shared by
/// several generations. Both registration forms use these transitions.
class VehicleClassificationSelection {
  BrandRef? brand;
  ModelRef? model;
  TrimRef? trim;
  EngineTypeRef? engineType;
  DrivetrainRef? drivetrain;
  String? engineCode;

  VehicleClassificationSelection();

  factory VehicleClassificationSelection.fromIds(
    CatalogRefs refs, {
    int? brandId,
    int? modelId,
    int? trimId,
    int? engineTypeId,
    int? drivetrainId,
    String? engineCode,
  }) {
    final selection = VehicleClassificationSelection();
    selection.brand = refs.brands.where((b) => b.id == brandId).firstOrNull;
    selection.model = refs.vehicleModels
        .where((m) => m.id == modelId && m.brandId == selection.brand?.id)
        .firstOrNull;
    selection.trim = refs.trims
        .where((t) => t.id == trimId && t.vehicleModelId == selection.model?.id)
        .firstOrNull;
    selection.engineType = refs.engineTypes
        .where((e) => e.id == engineTypeId).firstOrNull;
    selection.drivetrain = refs.drivetrains
        .where((d) => d.id == drivetrainId).firstOrNull;
    selection.engineCode = engineCode;
    return selection;
  }

  /// A changed brand invalidates everything derived from its old model.
  void selectBrand(BrandRef? value) {
    if (brand?.id == value?.id) return;
    brand = value;
    model = null;
    clearModelDetails();
  }

  void selectModel(ModelRef? value) {
    if (model?.id == value?.id) return;
    if (value != null && value.brandId != brand?.id) {
      throw ArgumentError('The model must belong to the selected brand.');
    }
    model = value;
    clearModelDetails();
  }

  /// Also used when replacing a decoded identity or switching to free text.
  void clearModelDetails() {
    trim = null;
    engineType = null;
    drivetrain = null;
    engineCode = null;
  }

  Map<String, dynamic> toPayload({
    required bool editing,
    bool allowFreeModel = false,
    String? modelLibre,
  }) => {
    'brand_id': brand?.id,
    if (editing || model != null || allowFreeModel)
      'vehicle_model_id': model?.id,
    if (allowFreeModel)
      'model_libre': model == null ? modelLibre?.trim() : null,
    // Omission during a PATCH/PUT retains the previous relationship. An
    // explicit null is required to remove a previously selected trim.
    if (editing || trim != null) 'trim_id': trim?.id,
    if (editing || engineType != null) 'engine_type_id': engineType?.id,
    if (editing || drivetrain != null) 'drivetrain_id': drivetrain?.id,
    if (editing || engineCode?.isNotEmpty == true)
      'engine_code': engineCode?.toUpperCase(),
  };
}
