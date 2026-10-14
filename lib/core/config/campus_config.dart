/// Campus center and radius supplied when building/running the app.
/// Build-time values override the selected defaults below.
class CampusConfig {
  CampusConfig._();

  static const _latitudeValue = String.fromEnvironment(
    'CAMPUS_LATITUDE',
    defaultValue: '28.3658',
  );
  static const _longitudeValue = String.fromEnvironment(
    'CAMPUS_LONGITUDE',
    defaultValue: '77.540403',
  );
  static const _radiusValue = String.fromEnvironment(
    'CAMPUS_RADIUS_METERS',
    defaultValue: '1000',
  );

  static final double? latitude = double.tryParse(_latitudeValue);
  static final double? longitude = double.tryParse(_longitudeValue);
  static final double? radiusMeters = double.tryParse(_radiusValue);

  static bool get isConfigured =>
      latitude != null &&
      longitude != null &&
      radiusMeters != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      radiusMeters!.isFinite &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180 &&
      radiusMeters! > 0;
}
