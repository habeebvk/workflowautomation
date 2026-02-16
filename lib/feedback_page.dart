import 'package:aiworkflowautomation/model/feedback_model.dart';
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double value = 3.5;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_nameController.text.isEmpty || _feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final feedback = FeedbackModel(
      name: _nameController.text,
      content: _feedbackController.text,
      rating: value,
    );

    await _dbService.insertFeedback(feedback);

    // 🔹 Trigger Notification
    await _dbService.insertNotification(
      NotificationModel(
        title: "New Feedback Received",
        message: "${_nameController.text} gave a rating of $value stars",
        date: DateTime.now().toString(),
        type: "feedback",
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback Submitted Successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final double maxWidth = isMobile ? double.infinity : 500;
    final double titleSize = isMobile ? 18 : 20;
    final double fieldSpacing = isMobile ? 12 : 16;
    final double starSize = isMobile ? 20 : 24;
    final double buttonHeight = isMobile ? 50 : 56;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: Text(
          "Feedback",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: titleSize,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: maxWidth,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 28),
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// 🔹 NAME
                _buildField("Enter Name", controller: _nameController),

                SizedBox(height: fieldSpacing),

                /// 🔹 FEEDBACK
                _buildField(
                  "Your Feedback Here",
                  maxLines: 6,
                  controller: _feedbackController,
                ),

                const SizedBox(height: 24),

                /// 🔹 RATING
                Align(
                  alignment: Alignment.centerLeft,
                  child: RatingStars(
                    value: value,
                    onValueChanged: (v) {
                      setState(() => value = v);
                    },
                    starBuilder: (index, color) =>
                        Icon(Icons.star, color: color),
                    starCount: 5,
                    starSize: starSize,
                    maxValue: 5,
                    starSpacing: 4,
                    valueLabelVisibility: true,
                    valueLabelRadius: 10,
                    valueLabelPadding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 8,
                    ),
                    valueLabelMargin: const EdgeInsets.only(right: 8),
                    starOffColor: const Color(0xffe7e8ea),
                    starColor: Colors.yellow,
                    animationDuration: const Duration(milliseconds: 800),
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔹 SUBMIT
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitFeedback,
                    child: Text(
                      "Submit",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Common TextField
  Widget _buildField(
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
