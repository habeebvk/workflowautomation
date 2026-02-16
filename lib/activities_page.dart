import 'package:aiworkflowautomation/model/activity_model.dart';
import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityPage extends StatefulWidget {
  final ActivityModel activity;
  final UserModel? user; // 🔹 User context

  const ActivityPage({super.key, required this.activity, this.user});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final TextEditingController _answerController = TextEditingController();
  List<Map<String, dynamic>> _answers = [];
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.activity.isBookmarked;
    if (widget.user != null && widget.user!.role.toLowerCase() == 'teacher') {
      _fetchAnswers();
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    await DatabaseService().updateActivityBookmark(
      widget.activity.id!,
      _isBookmarked,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked ? "Added to bookmarks" : "Removed from bookmarks",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _fetchAnswers() async {
    final answers = await DatabaseService().getActivityAnswers(
      widget.activity.id!,
    );
    if (mounted) {
      setState(() {
        _answers = answers;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to answer.")),
      );
      return;
    }

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please write an answer.")));
      return;
    }

    try {
      await DatabaseService().insertActivityAnswer(
        widget.activity.id!,
        widget.user!.name,
        _answerController.text.trim(),
      );

      // 🔹 Trigger Notification
      await DatabaseService().insertNotification(
        NotificationModel(
          title: "New Answer Received",
          message: "${widget.user!.name} answered: ${widget.activity.question}",
          date: DateTime.now().toString(),
          type: "answer",
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Answer submitted successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error submitting answer: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double maxWidth = isMobile ? double.infinity : 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.subject, style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.blueGrey : Colors.black,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: maxWidth,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // 🔹 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Teacher: ${widget.activity.teacher}",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Posted: ${widget.activity.date.split(' ')[0]}",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 🔹 ACTIVITY CONTENT
                Text(
                  widget.activity.question,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                const Divider(),

                const SizedBox(height: 20),

                // 🔹 ANSWER INPUT
                if (widget.user != null &&
                    widget.user!.role.toLowerCase() == "student") ...[
                  Text(
                    "Your Answer",
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _answerController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Type your answer here...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔹 SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: isMobile ? 52 : 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submitAnswer,
                      child: Text(
                        "Submit Answer",
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 16 : 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else if (widget.user != null &&
                    widget.user!.role.toLowerCase() == "teacher") ...[
                  Text(
                    "Student Answers",
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_answers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No answers yet.",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._answers.map(
                      (answer) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  answer['student_name'] ?? 'Unknown',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  answer['date'] != null
                                      ? answer['date'].toString().split(' ')[0]
                                      : '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              answer['answer'] ?? '',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else if (widget.user != null) ...[
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          "Only students can submit answers.",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        Text(
                          "Logged in as ${widget.user!.role}",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
