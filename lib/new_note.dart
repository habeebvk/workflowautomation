import 'package:aiworkflowautomation/model/note_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewNoteScreen extends StatefulWidget {
  final NoteData note;
  const NewNoteScreen({super.key, required this.note});

  @override
  State<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.note.isBookmarked;
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      if (widget.note.id != null) {
        await DatabaseService().updateNoteBookmark(
          widget.note.id!,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating bookmark: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final double maxWidth = isMobile ? double.infinity : 600;
    final double titleSize = isMobile ? 16 : 18;
    final double authorSize = isMobile ? 14 : 15;
    final double buttonHeight = isMobile ? 50 : 56;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.subject, style: GoogleFonts.poppins()),
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
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // 🔹 HEADER ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.note.subject,
                      style: GoogleFonts.poppins(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.note.semester,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 🔹 AUTHOR
                Text(
                  "By ${widget.note.teacher}",
                  style: GoogleFonts.poppins(
                    fontSize: authorSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // 🔹 DIVIDER
                const Divider(thickness: 1),

                const SizedBox(height: 24),

                // 🔹 CONTENT
                Text(
                  widget.note.content,
                  style: GoogleFonts.poppins(fontSize: 16, height: 1.5),
                ),

                const SizedBox(height: 24),

                // 🔹 ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBookmarked
                          ? Colors.grey
                          : Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _toggleBookmark,
                    child: Text(
                      _isBookmarked
                          ? "Remove from Bookmarks"
                          : "Add to Bookmarks",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
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
}
