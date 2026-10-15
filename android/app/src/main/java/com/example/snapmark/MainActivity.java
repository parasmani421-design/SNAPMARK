package com.example.snapmark;

import android.content.Intent;
import android.provider.Settings;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.util.HashMap;
import java.util.Map;

/** Android-side attendance security and campus geofence checks exposed to Flutter. */
public class MainActivity extends FlutterActivity {
    private static final String INTEGRITY_CHANNEL = "com.snapmark/device_integrity";
    private static final double MAX_ACCURACY_METERS = 100.0;
    private static final long MAX_FIX_AGE_MILLIS = 20_000L;
    private static final long MAX_FUTURE_SKEW_MILLIS = 5_000L;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), INTEGRITY_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "verifyAttendanceLocation":
                            result.success(verifyAttendanceLocation(call.arguments));
                            break;
                        case "openDeveloperOptionsSettings":
                            openDeveloperOptionsSettings(result);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    /** Validates the Android signals and GPS fix collected by Flutter. */
    private Map<String, Object> verifyAttendanceLocation(Object rawArguments) {
        Map<String, Object> response = new HashMap<>();
        if (!(rawArguments instanceof Map)) {
            response.put("error", "Attendance location data could not be verified. Please try again.");
            return response;
        }

        Map<?, ?> args = (Map<?, ?>) rawArguments;
        double latitude = number(args, "latitude");
        double longitude = number(args, "longitude");
        double accuracy = number(args, "accuracy");
        double campusLatitude = number(args, "campusLatitude");
        double campusLongitude = number(args, "campusLongitude");
        double radius = number(args, "radiusMeters");
        long fixTimeMillis = (long) number(args, "fixTimeMillis");
        boolean isMocked = Boolean.TRUE.equals(args.get("isMocked"));

        boolean developerOptions = readGlobalSetting(Settings.Global.DEVELOPMENT_SETTINGS_ENABLED);
        boolean adbEnabled = readGlobalSetting(Settings.Global.ADB_ENABLED);
        response.put("developerOptionsEnabled", developerOptions);
        response.put("adbEnabled", adbEnabled);

        if (developerOptions || adbEnabled) {
            response.put("error", "Developer options or USB debugging are enabled. Turn them off before scanning the attendance QR.");
            return response;
        }
        if (isMocked) {
            response.put("error", "Android reported a mock location. Turn off mock-location apps before scanning the attendance QR.");
            return response;
        }
        if (!isFinite(latitude) || !isFinite(longitude)
                || !isFinite(campusLatitude) || !isFinite(campusLongitude)
                || !isFinite(accuracy) || accuracy <= 0 || accuracy > MAX_ACCURACY_METERS
                || !isFinite(radius) || radius <= 0) {
            response.put("error", "GPS signal is too weak or attendance location settings are invalid. Retry with a clearer GPS signal.");
            return response;
        }

        long ageMillis = System.currentTimeMillis() - fixTimeMillis;
        if (ageMillis > MAX_FIX_AGE_MILLIS || ageMillis < -MAX_FUTURE_SKEW_MILLIS) {
            response.put("error", "Location reading is stale. Refresh GPS and retry.");
            return response;
        }

        float[] distance = new float[1];
        android.location.Location.distanceBetween(
                latitude, longitude, campusLatitude, campusLongitude, distance);
        double distanceMeters = distance[0];
        if (distanceMeters + accuracy > radius) {
            if (distanceMeters - accuracy > radius) {
                response.put("error", "Phone location is about " + Math.round(distanceMeters)
                        + " m from the campus center; the allowed radius is " + Math.round(radius) + " m.");
            } else {
                response.put("error", "Location is near the campus boundary (about "
                        + Math.round(distanceMeters) + " m away, GPS accuracy ±"
                        + Math.round(accuracy) + " m). Move farther inside and retry.");
            }
            return response;
        }

        response.put("error", null);
        return response;
    }

    private double number(Map<?, ?> args, String key) {
        Object value = args.get(key);
        return value instanceof Number ? ((Number) value).doubleValue() : Double.NaN;
    }

    private boolean readGlobalSetting(String name) {
        return Settings.Global.getInt(getContentResolver(), name, 0) != 0;
    }

    private boolean isFinite(double value) {
        return !Double.isNaN(value) && !Double.isInfinite(value);
    }

    private void openDeveloperOptionsSettings(MethodChannel.Result result) {
        try {
            startActivity(new Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS));
            result.success(true);
        } catch (Exception developmentSettingsUnavailable) {
            try {
                startActivity(new Intent(Settings.ACTION_SETTINGS));
                result.success(true);
            } catch (Exception settingsUnavailable) {
                result.error("SETTINGS_UNAVAILABLE", settingsUnavailable.getMessage(), null);
            }
        }
    }
}
