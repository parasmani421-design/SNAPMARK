import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceAccessRequest {
  const DeviceAccessRequest({
    required this.id,
    required this.studentEmail,
    required this.studentName,
    required this.deviceId,
    required this.deviceLabel,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
  });

  final String id;
  final String studentEmail;
  final String studentName;
  final String deviceId;
  final String deviceLabel;
  final String status;
  final String requestedAt;
  final String? reviewedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentEmail': studentEmail,
    'studentName': studentName,
    'deviceId': deviceId,
    'deviceLabel': deviceLabel,
    'status': status,
    'requestedAt': requestedAt,
    'reviewedAt': reviewedAt,
  };

  factory DeviceAccessRequest.fromJson(Map<String, dynamic> json) =>
      DeviceAccessRequest(
        id: json['id'] as String? ?? '',
        studentEmail: json['studentEmail'] as String? ?? '',
        studentName: json['studentName'] as String? ?? 'Student',
        deviceId: json['deviceId'] as String? ?? '',
        deviceLabel: json['deviceLabel'] as String? ?? 'This device',
        status: json['status'] as String? ?? 'pending',
        requestedAt: json['requestedAt'] as String? ?? '',
        reviewedAt: json['reviewedAt'] as String?,
      );

  DeviceAccessRequest copyWith({String? status, String? reviewedAt}) =>
      DeviceAccessRequest(
        id: id,
        studentEmail: studentEmail,
        studentName: studentName,
        deviceId: deviceId,
        deviceLabel: deviceLabel,
        status: status ?? this.status,
        requestedAt: requestedAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );
}

class DeviceAccessRequestStore {
  DeviceAccessRequestStore._();

  static const _requestsKey = 'snapmark.device_access_requests.v1';
  static const _deviceIdKey = 'snapmark.installation_device_id.v1';

  static Future<String> currentDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final savedId = preferences.getString(_deviceIdKey);
    if (savedId != null && savedId.isNotEmpty) return savedId;
    final random = Random.secure();
    final id = List<int>.generate(
      12,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    await preferences.setString(_deviceIdKey, id);
    return id;
  }

  static String get currentDeviceLabel => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android phone',
    TargetPlatform.iOS => 'iPhone or iPad',
    TargetPlatform.macOS => 'Mac',
    TargetPlatform.windows => 'Windows device',
    TargetPlatform.linux => 'Linux device',
    TargetPlatform.fuchsia => 'Fuchsia device',
  };

  static Future<List<DeviceAccessRequest>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_requestsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
            (item) =>
                DeviceAccessRequest.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList()
        ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<DeviceAccessRequest?> forStudentDevice(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final deviceId = await currentDeviceId();
    for (final request in await loadAll()) {
      if (request.studentEmail.toLowerCase() == normalizedEmail &&
          request.deviceId == deviceId) {
        return request;
      }
    }
    return null;
  }

  static Future<bool> isApproved(String email) async =>
      (await forStudentDevice(email))?.status == 'approved';

  static Future<DeviceAccessRequest> submitRequest({
    required String studentEmail,
    required String studentName,
  }) async {
    final email = studentEmail.trim().toLowerCase();
    final deviceId = await currentDeviceId();
    final requests = await loadAll();
    final existingIndex = requests.indexWhere(
      (request) =>
          request.studentEmail.toLowerCase() == email &&
          request.deviceId == deviceId,
    );
    final now = DateTime.now().toIso8601String();
    final request = DeviceAccessRequest(
      id: existingIndex >= 0 ? requests[existingIndex].id : '$email-$deviceId',
      studentEmail: email,
      studentName: studentName.trim().isEmpty ? email : studentName.trim(),
      deviceId: deviceId,
      deviceLabel: currentDeviceLabel,
      status: 'pending',
      requestedAt: now,
    );
    if (existingIndex >= 0) {
      requests[existingIndex] = request;
    } else {
      requests.insert(0, request);
    }
    await _save(requests);
    return request;
  }

  static Future<void> review(String id, {required bool approve}) async {
    final requests = await loadAll();
    final index = requests.indexWhere((request) => request.id == id);
    if (index < 0) return;
    requests[index] = requests[index].copyWith(
      status: approve ? 'approved' : 'rejected',
      reviewedAt: DateTime.now().toIso8601String(),
    );
    await _save(requests);
  }

  static Future<void> _save(List<DeviceAccessRequest> requests) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _requestsKey,
      jsonEncode(requests.map((request) => request.toJson()).toList()),
    );
  }
}
