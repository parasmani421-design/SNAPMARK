import 'package:flutter/material.dart';

import '../../core/services/device_access_request_store.dart';

class AdminDeviceRequestsScreen extends StatefulWidget {
  const AdminDeviceRequestsScreen({super.key});

  @override
  State<AdminDeviceRequestsScreen> createState() =>
      _AdminDeviceRequestsScreenState();
}

class _AdminDeviceRequestsScreenState extends State<AdminDeviceRequestsScreen> {
  List<DeviceAccessRequest> _requests = [];
  bool _loading = true;
  String? _reviewingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await DeviceAccessRequestStore.loadAll();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _loading = false;
    });
  }

  Future<void> _review(DeviceAccessRequest request, bool approve) async {
    setState(() => _reviewingId = request.id);
    await DeviceAccessRequestStore.review(request.id, approve: approve);
    await _load();
    if (!mounted) return;
    setState(() => _reviewingId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? '${request.studentName} device approved for QR attendance.'
              : 'Device request from ${request.studentName} declined.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendingCount = _requests
        .where((request) => request.status == 'pending')
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('Device requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device requests',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$pendingCount waiting for review',
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: .58),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh requests',
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFB454).withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xffFFB454).withValues(alpha: .22),
                      ),
                    ),
                    child: const Text(
                      'Approve only after checking the student and device. Approval unlocks attendance QR scanning for that account on this app installation.',
                      style: TextStyle(fontSize: 11, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_requests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.phonelink_setup_rounded,
                            size: 34,
                            color: colors.onSurface.withValues(alpha: .45),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'No device requests yet',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Student requests will appear here for review.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: .58),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final request in _requests) _requestCard(request),
                ],
              ),
            ),
    );
  }

  Widget _requestCard(DeviceAccessRequest request) {
    final colors = Theme.of(context).colorScheme;
    final pending = request.status == 'pending';
    final statusColor = switch (request.status) {
      'approved' => const Color(0xff35C995),
      'rejected' => const Color(0xffFF7373),
      _ => const Color(0xffFFB454),
    };
    final reviewing = _reviewingId == request.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.onSurface.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: .13),
                child: Icon(Icons.phone_android_rounded, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.studentEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: .58),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _infoRow(Icons.devices_rounded, request.deviceLabel),
          const SizedBox(height: 7),
          _infoRow(
            Icons.fingerprint_rounded,
            'Installation ID · ${request.deviceId.substring(request.deviceId.length - 6).toUpperCase()}',
          ),
          const SizedBox(height: 7),
          _infoRow(Icons.schedule_rounded, _formatDate(request.requestedAt)),
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: reviewing ? null : () => _review(request, false),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: reviewing ? null : () => _review(request, true),
                    icon: reviewing
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .67),
            fontSize: 10,
          ),
        ),
      ),
    ],
  );

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
