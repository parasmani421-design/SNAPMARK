import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/student_directory_store.dart';

class StudentMentorScreen extends StatelessWidget {
  const StudentMentorScreen({
    required this.mentor,
    required this.mentorEmail,
    super.key,
  });

  final FacultyRecord? mentor;
  final String mentorEmail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasProfile = mentor != null;
    final name = mentor?.value('full_name') ?? '';
    final email = mentor?.value('email') ?? mentorEmail;
    final phone = mentor?.value('phone') ?? '';
    final designation = mentor?.value('designation') ?? '';
    final department = mentor?.value('department') ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Mentor')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text(
            'FACULTY SUPPORT',
            style: TextStyle(
              color: colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Your Mentor',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Reach out to your assigned faculty member for academic guidance.',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: .62),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff1E467E), Color(0xff5148A9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff3977FF).withValues(alpha: .16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: .16),
                  child: Text(
                    hasProfile ? _initials(name) : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasProfile ? name : 'Mentor not assigned',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasProfile
                            ? [
                                designation,
                                department,
                              ].where((value) => value.isNotEmpty).join(' · ')
                            : 'Your campus admin can assign a mentor.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (hasProfile && email.isNotEmpty)
            _contactRow(
              context,
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: email,
            ),
          if (hasProfile && phone.isNotEmpty)
            _contactRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: phone,
            ),
          if (!hasProfile && mentorEmail.isNotEmpty)
            _contactRow(
              context,
              icon: Icons.mail_outline_rounded,
              label: 'Assigned faculty email',
              value: mentorEmail,
            ),
          if (!hasProfile)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mentorEmail.isEmpty
                          ? 'Ask your campus admin to assign a faculty mentor to your student record.'
                          : 'This faculty profile is not available on this device yet. Contact your campus admin if you need help.',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: .7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .38),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(
          label,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: .58),
            fontSize: 10,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.copy_rounded, size: 17, color: colors.primary),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('$label copied')));
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
