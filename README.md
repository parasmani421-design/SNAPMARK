# SnapMark

## Campus attendance location

Before opening the existing QR scanner, SnapMark checks the phone's current
location against the institution's configured campus center and radius. The
currently selected defaults are latitude `28.464950`, longitude `77.506610`,
and a 2 kilometer radius.

Run on Android with those defaults:

```sh
flutter run
```

To override them with verified campus values:

```sh
flutter run \
  --dart-define=CAMPUS_LATITUDE=<campus-latitude> \
  --dart-define=CAMPUS_LONGITUDE=<campus-longitude> \
  --dart-define=CAMPUS_RADIUS_METERS=<radius-in-meters>
```

Location permission and phone Location services must be enabled. If GPS
uncertainty overlaps the geofence boundary, SnapMark asks the student to move
farther inside and retry. Location is only requested while checking
attendance; no background location permission is used.
