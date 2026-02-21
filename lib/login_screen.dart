import 'package:aiworkflowautomation/home_screen.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/signup.dart';
import 'package:aiworkflowautomation/teachers/teacher_home.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String selectedRole = "Student";
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    // Note: We removed the strict email regex since it could be a phone number from signup
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final identifier = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final user = await _dbService.getUser(identifier);

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("User not found")));
        }
        return;
      }

      if (user.password != password) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Incorrect password")));
        }
        return;
      }

      if (user.role != selectedRole) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User is not registered as $selectedRole")),
          );
        }
        return;
      }

      if (mounted) {
        if (selectedRole == "Teacher") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TeacherHome(user: user)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
          );
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Logged in as $selectedRole")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final double maxWidth = isMobile ? double.infinity : 420;
    final double titleSize = isMobile
        ? 32
        : isTablet
        ? 36
        : 40;
    final double fieldSpacing = isMobile ? 10 : 14;
    final double buttonHeight = isMobile ? 56 : 60;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: maxWidth,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 28),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    // 🔹 TITLE
                    Text(
                      "Login",
                      style: GoogleFonts.poppins(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: isMobile ? 40 : 60),

                    // 🔹 EMAIL
                    _buildField(
                      controller: _emailController,
                      hint: "Enter Email",
                      validator: _validateEmail,
                      context: context,
                    ),

                    SizedBox(height: fieldSpacing),

                    // 🔹 PASSWORD
                    _buildField(
                      controller: _passwordController,
                      hint: "Enter Password",
                      obscure: true,
                      validator: _validatePassword,
                      context: context,
                    ),

                    SizedBox(height: fieldSpacing),

                    // 🔹 ROLE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white, // ✅ same as Signup
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),

                        dropdownColor:
                            Colors.white, // ✅ dropdown menu background

                        style: GoogleFonts.poppins(
                          color: Colors.black, // ✅ selected text color
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: "Teacher",
                            child: Text("Teacher"),
                          ),
                          DropdownMenuItem(
                            value: "Student",
                            child: Text("Student"),
                          ),
                        ],

                        onChanged: (value) =>
                            setState(() => selectedRole = value!),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔹 LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            211,
                            34,
                            34,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(
                          "Submit",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔹 SIGNUP
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Don't have an account? Signup",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable Field
  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool obscure = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,

      // ✅ Typing text color
      style: TextStyle(color: isDark ? Colors.black : Colors.black),

      decoration: InputDecoration(
        hintText: hint,

        // ✅ Hint color
        hintStyle: TextStyle(color: Colors.grey.shade600),

        filled: true,
        fillColor: Colors.white, // keep white in both modes

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}
