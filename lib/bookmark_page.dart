import 'package:aiworkflowautomation/activities_page.dart';
import 'package:aiworkflowautomation/model/activity_model.dart';
import 'package:aiworkflowautomation/model/note_model.dart';
import 'package:aiworkflowautomation/new_note.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  List<ActivityModel> _bookmarkedActivities = [];
  List<NoteData> _bookmarkedNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    final activityBookmarks = await DatabaseService().getBookmarkedActivities();
    final noteBookmarks = await DatabaseService().getBookmarkedNotes();

    if (mounted) {
      setState(() {
        _bookmarkedActivities = activityBookmarks;
        _bookmarkedNotes = noteBookmarks;
        _isLoading = false;
      });
    }
  }

  Widget _bookmarkCard({
    required String title,
    required String subtitle,
    required String dateOrPages,
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
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔹 TEXT INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 13)),
                  Text(dateOrPages, style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),

            // 🔹 ACTION ICON
            GestureDetector(
              onTap: onIconPressed,
              child: Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blueGrey,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double maxWidth = isMobile ? double.infinity : 700;

    return Scaffold(
      appBar: AppBar(title: Text("Bookmarks", style: GoogleFonts.poppins())),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Container(
                  width: maxWidth,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_bookmarkedActivities.isEmpty &&
                          _bookmarkedNotes.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: Text(
                              "No bookmarks yet",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),

                      if (_bookmarkedNotes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          "Notes",
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._bookmarkedNotes.map(
                          (note) => Column(
                            children: [
                              _bookmarkCard(
                                title: note.subject,
                                subtitle: "By ${note.teacher}",
                                dateOrPages: note.semester,
                                isMobile: isMobile,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NewNoteScreen(note: note),
                                    ),
                                  ).then((_) => _fetchBookmarks());
                                },
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ],

                      if (_bookmarkedActivities.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          "Activities",
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._bookmarkedActivities.map(
                          (activity) => Column(
                            children: [
                              _bookmarkCard(
                                title: activity.subject,
                                subtitle: "By ${activity.teacher}",
                                dateOrPages: activity.date.split(' ')[0],
                                isMobile: isMobile,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ActivityPage(
                                        activity: activity,
                                        // user: null,
                                      ),
                                    ),
                                  ).then((_) => _fetchBookmarks());
                                },
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
