import '../face/face_registration_screen.dart';
import 'package:flutter/material.dart';

import '../../core/services/student_directory_store.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final enrollmentController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    enrollmentController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        enrollmentController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    try {
      await StudentDirectoryStore.saveProfileForEmail(
        emailController.text.trim(),
        {
          'full_name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'enrollment_number': enrollmentController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the student record. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Registration Successful")));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Student Registration"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.person_add_alt_1,
                color: Colors.blueAccent,
                size: 90,
              ),

              const SizedBox(height: 15),

              const Text(
                "Create Your Account",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              CustomTextField(
                hint: "Full Name",
                icon: Icons.person,
                controller: nameController,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                hint: "Enrollment Number",
                icon: Icons.badge,
                controller: enrollmentController,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                hint: "College Email",
                icon: Icons.email,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                hint: "Mobile Number",
                icon: Icons.phone,
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                hint: "Password",
                icon: Icons.lock,
                controller: passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                hint: "Confirm Password",
                icon: Icons.lock_outline,
                controller: confirmPasswordController,
                obscureText: true,
              ),

              const SizedBox(height: 30),

              CustomButton(text: "REGISTER", onPressed: register),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
