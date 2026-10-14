import 'package:flutter/material.dart';

import '../../core/services/device_access_request_store.dart';
import '../../core/services/student_directory_store.dart';

class RequestCenterScreen extends StatefulWidget {
  const RequestCenterScreen({super.key});

  @override
  State<RequestCenterScreen> createState() => _RequestCenterScreenState();
}

class _RequestCenterScreenState extends State<RequestCenterScreen> {
  String? _email;
  String _studentName = 'Student';
  DeviceAccessRequest? _request;
  String _deviceId = '';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await StudentDirectoryStore.activeEmail();
    final deviceId = await DeviceAccessRequestStore.currentDeviceId();
    final student = email == null
        ? null
        : await StudentDirectoryStore.findByEmail(email);
    final request = email == null
        ? null
        : await DeviceAccessRequestStore.forStudentDevice(email);
    if (!mounted) return;
    setState(() {
      _email = email;
      _studentName = student?.value('full_name') ?? 'Student';
      _deviceId = deviceId;
      _request = request;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final email = _email;
    if (email == null || _submitting) return;
    setState(() => _submitting = true);
    final request = await DeviceAccessRequestStore.submitRequest(
      studentEmail: email,
      studentName: _studentName,
    );
    if (!mounted) return;
    setState(() {
      _request = request;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final request = _request;
    final status = request?.status ?? 'not_requested';
    final statusColor = switch (status) {
      'approved' => const Color(0xff35C995),
      'rejected' => const Color(0xffFF7373),
      'pending' => const Color(0xffFFB454),
      _ => colors.onSurface.withValues(alpha: .5),
    };
    final statusTitle = switch (status) {
      'approved' => 'Device approved',
      'rejected' => 'Request declined',
      'pending' => 'Waiting for admin',
      _ => 'Device not registered',
    };
    final statusMessage = switch (status) {
      'approved' => 'Attendance scanning is enabled on this device.',
      'rejected' => 'This device was not approved. You can send a new request.',
      'pending' =>
        'Attendance stays locked until an admin approves this request.',
      _ =>
        'Ask an admin to approve this device before scanning attendance QR codes.',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh request status',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff155EEF), Color(0xff4527A0)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.phonelink_lock_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Register this device',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'A new phone must be approved by the college admin before it can scan attendance QR codes.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: .08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: statusColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              statusTitle,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: .68),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _detailRow('Student', _studentName, colors.onSurface),
                      const SizedBox(height: 7),
                      _detailRow(
                        'Account',
                        _email ?? 'Not signed in',
                        colors.onSurface,
                      ),
                      const SizedBox(height: 7),
                      _detailRow(
                        'Device',
                        '${DeviceAccessRequestStore.currentDeviceLabel} · ${_deviceId.length > 6 ? _deviceId.substring(_deviceId.length - 6).toUpperCase() : _deviceId}',
                        colors.onSurface,
                      ),
                      if (request != null) ...[
                        const SizedBox(height: 7),
                        _detailRow(
                          'Requested',
                          _formatDate(request.requestedAt),
                          colors.onSurface,
                        ),
                      ],
                      if (status != 'approved') ...[
                        const SizedBox(height: 17),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                _email == null ||
                                    status == 'pending' ||
                                    _submitting
                                ? null
                                : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              status == 'pending'
                                  ? 'Request sent'
                                  : status == 'rejected'
                                  ? 'Send again'
                                  : 'Request device approval',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFB454).withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xffFFB454).withValues(alpha: .22),
                    ),
                  ),
                  child: const Text(
                    'Demo mode: requests are saved on this app installation and appear in its Admin panel. Cross-device approval sync needs the campus backend.',
                    style: TextStyle(fontSize: 11, height: 1.45),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _detailRow(String label, String value, Color textColor) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 76,
        child: Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: .5),
            fontSize: 11,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
