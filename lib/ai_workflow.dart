import 'package:aiworkflowautomation/controller/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/activities_page.dart';
import 'package:aiworkflowautomation/model/activity_model.dart';
import 'package:aiworkflowautomation/model/note_model.dart';
import 'package:aiworkflowautomation/view/deepseek_chat_screen.dart';
import 'package:aiworkflowautomation/bookmark_page.dart';
import 'package:aiworkflowautomation/new_note.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:aiworkflowautomation/service/deepseek_service.dart';
import 'package:aiworkflowautomation/model/userModel.dart'; // Keep for ChatMessage? Or remove if unused?
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';

class AiNoteScreen extends StatefulWidget {
  final bool canAdd;
  final UserModel? user;
  const AiNoteScreen({super.key, this.canAdd = false, this.user});

  @override
  State<AiNoteScreen> createState() => _AiNoteScreenState();
}

class _AiNoteScreenState extends State<AiNoteScreen> {
  List<NoteData> _notes = [];
  List<ActivityModel> _activities = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final notes = await DatabaseService().getNotes();
    final activities = await DatabaseService().getActivities();
    setState(() {
      _notes = notes;
      _activities = activities;
    });
  }

  void _showAddNoteDialog(LanguageProvider languageProvider) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController teacherController = TextEditingController();
    final TextEditingController semController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String? selectedPdfPath;
    String? pdfFileName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                languageProvider.translate('add_note'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('subject_name'),
                    ),
                  ),
                  TextField(
                    controller: teacherController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('teacher_name'),
                    ),
                  ),
                  TextField(
                    controller: semController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('semester'),
                    ),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('content'),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );

                          if (result != null) {
                            setState(() {
                              selectedPdfPath = result.files.single.path;
                              pdfFileName = result.files.single.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          pdfFileName ??
                              languageProvider.translate('attach_pdf'),
                        ),
                      ),
                      if (pdfFileName != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedPdfPath = null;
                              pdfFileName = null;
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(languageProvider.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (subjectController.text.isNotEmpty &&
                        teacherController.text.isNotEmpty &&
                        semController.text.isNotEmpty &&
                        (contentController.text.isNotEmpty ||
                            selectedPdfPath != null)) {
                      try {
                        String? finalPdfPath;
                        if (selectedPdfPath != null) {
                          // Copy PDF to local storage
                          final directory =
                              await getApplicationDocumentsDirectory();
                          final String fileName = p.basename(selectedPdfPath!);
                          final String localPath = p.join(
                            directory.path,
                            fileName,
                          );
                          final File pdfFile = File(selectedPdfPath!);
                          await pdfFile.copy(localPath);
                          finalPdfPath = localPath;
                        }

                        final newNote = NoteData(
                          subject: subjectController.text,
                          teacher: teacherController.text,
                          semester: semController.text,
                          content: contentController.text,
                          pdfPath: finalPdfPath,
                        );

                        await DatabaseService().insertNote(newNote);

                        // 🔹 Trigger Notification
                        await DatabaseService().insertNotification(
                          NotificationModel(
                            title: languageProvider.translate(
                              'note_added_successfully',
                            ),
                            message:
                                "${teacherController.text} added a note for ${subjectController.text}",
                            date: DateTime.now().toString(),
                            type: "note",
                          ),
                        );

                        await _refreshData();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                languageProvider.translate(
                                  'note_added_successfully',
                                ),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint("Error adding note: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error adding note: $e")),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            languageProvider.translate(
                              'please_fill_all_fields',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(languageProvider.translate('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddActivityDialog(LanguageProvider languageProvider) {
    final TextEditingController teacherController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            languageProvider.translate('add_activity'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: teacherController,
                decoration: InputDecoration(
                  labelText: languageProvider.translate('teacher_name'),
                ),
              ),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: languageProvider.translate('subject_name'),
                ),
              ),
              TextField(
                controller: questionController,
                decoration: InputDecoration(
                  labelText: languageProvider.translate('question'),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(languageProvider.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (teacherController.text.isNotEmpty &&
                    subjectController.text.isNotEmpty &&
                    questionController.text.isNotEmpty) {
                  try {
                    final newActivity = ActivityModel(
                      teacher: teacherController.text,
                      subject: subjectController.text,
                      question: questionController.text,
                      date: DateTime.now().toString(),
                    );

                    await DatabaseService().insertActivity(newActivity);

                    // 🔹 Trigger Notification
                    await DatabaseService().insertNotification(
                      NotificationModel(
                        title: languageProvider.translate(
                          'activity_added_successfully',
                        ),
                        message:
                            "${teacherController.text} posted an activity for ${subjectController.text}",
                        date: DateTime.now().toString(),
                        type: "activity",
                      ),
                    );

                    await _refreshData();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            languageProvider.translate(
                              'activity_added_successfully',
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.translate('please_fill_all_fields'),
                      ),
                    ),
                  );
                }
              },
              child: Text(languageProvider.translate('add')),
            ),
          ],
        );
      },
    );
  }

  void _summarizeNote(NoteData note) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String contentToSummarize = note.content;

      if (note.pdfPath != null) {
        final File file = File(note.pdfPath!);
        if (await file.exists()) {
          final PdfDocument document = PdfDocument(
            inputBytes: await file.readAsBytes(),
          );
          contentToSummarize = PdfTextExtractor(document).extractText();
          document.dispose();

          if (contentToSummarize.trim().isEmpty) {
            contentToSummarize =
                note.content; // Fallback to content if PDF is empty
          }
        }
      }

      final DeepSeekChatService chatService = DeepSeekChatService();
      // Using a valid User message structure
      final String summary = await chatService.sendMessage([
        ChatMessage(
          role: "user",
          content:
              "Summarize the following content in 3 or 4 sentences:\nContent: $contentToSummarize",
        ),
      ]);

      if (mounted) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Summary: ${note.subject}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blueGrey),
                  onPressed: () async {
                    await _downloadSummary(note.subject, summary);
                  },
                  tooltip: "Download PDF",
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(summary, style: GoogleFonts.poppins(fontSize: 14)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to summarize: $e")));
      }
    }
  }

  Future<void> _downloadSummary(String subject, String summary) async {
    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 14);

      page.graphics.drawString(
        "Summary: $subject\n\n$summary",
        font,
        bounds: Rect.fromLTWH(
          0,
          0,
          page.getClientSize().width,
          page.getClientSize().height,
        ),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      final String fileName =
          "${subject.replaceAll(' ', '_')}_summary_${DateTime.now().millisecondsSinceEpoch}.pdf";

      final String? path = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("PDF Saved Successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to download PDF: $e")));
      }
    }
  }

  /// 🔹 Reusable Card Widget (Dark-mode safe)
  Widget _noteCard({
    required BuildContext context,
    required String title,
    required String subtitle1,
    String? subtitle2,
    required IconData icon,
    required bool isMobile,
    VoidCallback? onTap,
    VoidCallback? onIconPressed,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isMobile ? 16 : 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white, // ✅ Always white
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// TEXT SECTION
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black, // ✅ FIXED
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle1,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle2 != null)
                  Text(
                    subtitle2!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),

            /// ICON
            GestureDetector(
              onTap: onIconPressed,
              child: Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blueGrey,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isMobile = Responsive.isMobile(context);
    final double maxWidth = isMobile ? double.infinity : 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('ai_notes'),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
            tooltip: languageProvider.translate('language'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkPage()),
              );
            },
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

                /// 🔹 NOTES HEADER & ADD BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('notes'),
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.canAdd)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                _showAddNoteDialog(languageProvider),
                            icon: const Icon(
                              Icons.note_add,
                              color: Colors.blueGrey,
                            ),
                            tooltip: languageProvider.translate('add_note'),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showAddActivityDialog(languageProvider),
                            icon: const Icon(
                              Icons.post_add,
                              color: Colors.blueGrey,
                            ),
                            tooltip: languageProvider.translate('add_activity'),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._notes.map(
                  (note) => Column(
                    children: [
                      _noteCard(
                        context: context,
                        title: "${note.subject} - ${note.teacher}",
                        subtitle1: note.semester,
                        subtitle2: "0 pages", // Default
                        icon: Icons.compress,
                        isMobile: isMobile,
                        onIconPressed: () => _summarizeNote(note),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewNoteScreen(note: note),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// 🔹 ACTIVITIES
                Text(
                  languageProvider.translate('activities'),
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                ..._activities.map(
                  (activity) => Column(
                    children: [
                      _noteCard(
                        context: context,
                        title: activity.subject,
                        subtitle1: "By ${activity.teacher}",
                        subtitle2: activity.date.split(
                          ' ',
                        )[0], // Show date instead of question
                        icon: Icons.send,
                        isMobile: isMobile,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityPage(
                                activity: activity,
                                user: widget.user,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      /// 🔹 FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeepSeekChatScreen()),
          );
        },
        child: const Icon(Icons.speaker_notes_outlined, color: Colors.white),
      ),
    );
  }
}
