import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/services/student_directory_store.dart';
import '../dashboard/dashboard_screen.dart';
import '../teacher/teacher_dashboard.dart';
import '../teacher/admin_dashboard.dart';
import 'register_screen.dart';

enum _LoginRole { student, faculty, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;
  _LoginRole selectedRole = _LoginRole.student;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final email = emailController.text.trim().toLowerCase();
    final requiredTag = switch (selectedRole) {
      _LoginRole.student => '@student',
      _LoginRole.faculty => '@teacher',
      _LoginRole.admin => null,
    };
    if (requiredTag != null && !email.contains(requiredTag)) {
      _showMessage(
        'For ${selectedRole == _LoginRole.student ? 'Student' : 'Teacher'} login, email must include $requiredTag.',
      );
      return;
    }
    if (selectedRole == _LoginRole.admin &&
        passwordController.text.trim() != '1234') {
      _showMessage('Admin password must be 1234.');
      return;
    }

    if (selectedRole == _LoginRole.student) {
      await StudentDirectoryStore.clearActiveFacultyEmail();
      final normalizedEmail = emailController.text.trim().toLowerCase();
      if (await StudentDirectoryStore.isDeletedEmail(normalizedEmail)) {
        _showMessage(
          'This student record was removed. Please contact your campus administrator.',
        );
        return;
      }
      await StudentDirectoryStore.setActiveEmail(normalizedEmail);
      final existing = await StudentDirectoryStore.findByEmail(normalizedEmail);
      if (existing == null) {
        await StudentDirectoryStore.saveProfileForEmail(normalizedEmail, {
          'full_name': normalizedEmail.split('@').first,
          'email': normalizedEmail,
        });
      }
    } else if (selectedRole == _LoginRole.faculty) {
      await StudentDirectoryStore.clearActiveEmail();
      final facultyEmail = emailController.text.trim().toLowerCase();
      if (await StudentDirectoryStore.isDeletedFacultyEmail(facultyEmail)) {
        _showMessage(
          'This faculty record was removed. Please contact your campus administrator.',
        );
        return;
      }
      await StudentDirectoryStore.setActiveFacultyEmail(facultyEmail);
      final existingFaculty = await StudentDirectoryStore.findFacultyByEmail(
        facultyEmail,
      );
      if (existingFaculty == null) {
        await StudentDirectoryStore.saveFacultyProfileForEmail(facultyEmail, {
          'full_name': facultyEmail.split('@').first,
          'email': facultyEmail,
        });
      }
    } else {
      await StudentDirectoryStore.clearActiveIdentity();
    }

    if (!mounted) return;
    final Widget destination = switch (selectedRole) {
      _LoginRole.student => const DashboardScreen(),
      _LoginRole.faculty => const TeacherDashboard(),
      _LoginRole.admin => const AdminDashboard(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xff050A17),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: (MediaQuery.sizeOf(context).height * .44).clamp(
              300.0,
              380.0,
            ),
            child: Image.asset(
              'assets/images/campus_night.jpg',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xff06122B).withValues(alpha: .40),
                    const Color(0xff06122B).withValues(alpha: .62),
                    const Color(0xff050A17).withValues(alpha: .97),
                    const Color(0xff050A17),
                  ],
                  stops: const [0, .30, .64, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                children: [
                  SizedBox(
                    height: (MediaQuery.sizeOf(context).height * .31).clamp(
                      230.0,
                      285.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'BE PRESENT. BUILD YOUR FUTURE.',
                          style: TextStyle(
                            color: Color(0xffE5F0FF),
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Color(0xff031126), blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 19),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 19),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(19, 18, 19, 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xff0B1730,
                            ).withValues(alpha: .87),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff227AFF,
                                ).withValues(alpha: .14),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _roleSelector(),
                              const SizedBox(height: 17),
                              _inputField(
                                controller: emailController,
                                hint: 'University Email',
                                helper: 'yourname@galgotiasuniversity.edu.in',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 11),
                              _inputField(
                                controller: passwordController,
                                hint: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscure: hidePassword,
                                suffix: IconButton(
                                  onPressed: () => setState(
                                    () => hidePassword = !hidePassword,
                                  ),
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white60,
                                    size: 19,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showMessage(
                                    'Password reset will be available when account services are connected.',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xff72AEFF),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 1),
                              _gradientLoginButton(),
                              const SizedBox(height: 13),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(
                                        alpha: .16,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 11,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(
                                        alpha: .16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showMessage(
                                    'Google sign-in is not connected yet.',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: .17,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Color(0xff66A6FF),
                                    size: 27,
                                  ),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text(
                                    'Don’t have an account? ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xff72AEFF),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                    ),
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'SNAPMARK  ·  SMART ATTENDANCE',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .5),
                      fontSize: 9,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    const roles = [
      (role: _LoginRole.student, title: 'Student', icon: Icons.school_rounded),
      (
        role: _LoginRole.faculty,
        title: 'Faculty',
        icon: Icons.person_outline_rounded,
      ),
      (
        role: _LoginRole.admin,
        title: 'Admin',
        icon: Icons.admin_panel_settings_outlined,
      ),
    ];
    return Row(
      children: roles.map((item) {
        final selected = selectedRole == item.role;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => setState(() => selectedRole = item.role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 43,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xff3977FF).withValues(alpha: .36)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected
                        ? const Color(0xff5796FF).withValues(alpha: .55)
                        : Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: selected ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helper,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      helperText: helper,
      hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),
      helperStyle: const TextStyle(color: Colors.white38, fontSize: 9),
      prefixIcon: Icon(icon, color: Colors.white70, size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: .055),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .09)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff4C94FF), width: 1.2),
      ),
    ),
  );

  Widget _gradientLoginButton() => SizedBox(
    width: double.infinity,
    height: 51,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xff168CFF), Color(0xff245BFF), Color(0xff5750E8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2475FF).withValues(alpha: .30),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LOGIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    ),
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
