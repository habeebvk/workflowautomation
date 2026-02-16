import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String selectedRole = "Student";
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 3) return 'Enter at least 3 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm password required';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final identifier = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 🔹 Check if user already exists
      final existingUser = await _dbService.getUser(identifier);
      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User already exists')));
        }
        return;
      }

      final user = UserModel(
        name: name,
        identifier: identifier,
        password: password,
        role: selectedRole,
      );

      await _dbService.registerUser(user);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registered as $selectedRole')));
        Navigator.pop(context); // Go back to Login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final double maxWidth = isMobile ? double.infinity : 450;
    final double titleSize = isMobile
        ? 32
        : isTablet
        ? 36
        : 40;
    final double fieldSpacing = isMobile ? 10 : 14;
    final double buttonHeight = isMobile ? 56 : 60;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: maxWidth,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 30),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    /// 🔹 TITLE
                    Text(
                      "Register",
                      style: GoogleFonts.poppins(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: colors.onBackground,
                      ),
                    ),

                    const SizedBox(height: 40),

                    _buildField(
                      context: context,
                      controller: _nameController,
                      hint: "Enter Name",
                      validator: _validateName,
                      theme: theme,
                    ),

                    SizedBox(height: fieldSpacing),

                    _buildField(
                      context: context,
                      controller: _emailController,
                      hint: "Enter Email",
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      theme: theme,
                    ),

                    SizedBox(height: fieldSpacing),

                    _buildField(
                      context: context,
                      controller: _passwordController,
                      hint: "Enter Password",
                      obscure: true,
                      validator: _validatePassword,
                      theme: theme,
                    ),

                    SizedBox(height: fieldSpacing),

                    _buildField(
                      controller: _confirmPasswordController,
                      hint: "Confirm Password",
                      obscure: true,
                      validator: _validateConfirmPassword,
                      theme: theme,
                      context: context,
                    ),

                    SizedBox(height: fieldSpacing),

                    /// 🔹 ROLE DROPDOWN
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

                    /// 🔹 SUBMIT BUTTON
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
                        ),
                        onPressed: _submit,
                        child: Text(
                          "Submit",
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 🔹 SIGN IN
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account? Sign in",
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

  /// 🔹 Theme-aware TextField
  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,

      // ✅ Black typing text (both modes)
      style: GoogleFonts.poppins(color: Colors.black),

      decoration: InputDecoration(
        hintText: hint,

        // ✅ Same hint style as Login
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),

        filled: true,
        fillColor: Colors.white, // ✅ SAME AS LOGIN

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
