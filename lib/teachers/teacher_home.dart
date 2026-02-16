import 'package:aiworkflowautomation/controller/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/login_screen.dart';
import 'package:aiworkflowautomation/teachers/ai_substitutuion.dart';
import 'package:aiworkflowautomation/teachers/dashboard.dart';
import 'package:aiworkflowautomation/teachers/feedback_screen.dart';
import 'package:aiworkflowautomation/teachers/leaverequest_page.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:aiworkflowautomation/ai_workflow.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherHome extends StatefulWidget {
  final UserModel user;
  const TeacherHome({super.key, required this.user});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  Widget _activityTile({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
    required bool isMobile,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isMobile ? 16 : 18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ],
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
      drawer: AppsDrawer(user: widget.user),
      appBar: AppBar(
        title: Text(
          languageProvider.translate('home'),
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
            tooltip: languageProvider.translate('language'),
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

                /// 🔹 TITLE
                Text(
                  languageProvider.translate('recent_activity'),
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                StreamBuilder<List<NotificationModel>>(
                  stream: DatabaseService().notificationsStream,
                  builder: (context, snapshot) {
                    // Initial fetch if stream is empty but data exists
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Trigger initial fetch to populate stream if needed
                      DatabaseService().getNotifications().then(
                        (list) =>
                            // We can't easily add to stream from here without exposing controller,
                            // but we can show a FutureBuilder or just wait.
                            // Better yet, in initState we could populate it.
                            // Actually, let's just use a FutureBuilder that then switches to Stream?
                            // Or simpler: Just render from future if stream has no data yet?
                            // Standard pattern: StreamBuilder with initialData from a Future?
                            null,
                      );
                      // For now return empty or loading
                      return FutureBuilder<List<NotificationModel>>(
                        future: DatabaseService().getNotifications(),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.hasData) {
                            return _buildNotificationList(
                              futureSnapshot.data!,
                              isMobile,
                              languageProvider,
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final notifications = snapshot.data ?? [];
                    return _buildNotificationList(
                      notifications,
                      isMobile,
                      languageProvider,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    List<NotificationModel> notifications,
    bool isMobile,
    LanguageProvider languageProvider,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            languageProvider.translate('no_recent_activity'),
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: notifications.map((notification) {
        IconData icon;
        Color color;
        switch (notification.type) {
          case 'note':
            icon = Icons.note_add;
            color = Colors.lightGreen;
            break;
          case 'activity':
            icon = Icons.post_add;
            color = Colors.lightGreen;
            break;
          case 'answer':
            icon = Icons.question_answer;
            color = Colors.orange;
            break;
          case 'substitution':
            icon = Icons.swap_horiz;
            color = Colors.purple;
            break;
          case 'feedback':
            icon = Icons.feedback;
            color = Colors.blue;
            break;
          default:
            icon = Icons.notifications;
            color = Colors.grey;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _activityTile(
            icon: icon,
            title: notification.title,
            time: notification.date.split('.')[0],
            color: color,
            isMobile: isMobile,
            onTap: () {
              // Define navigation if needed based on type
            },
          ),
        );
      }).toList(),
    );
  }
}

class AppsDrawer extends StatelessWidget {
  final UserModel user;
  const AppsDrawer({super.key, required this.user});

  // Direct push navigation helper
  void _openScreen(BuildContext context, Widget page) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user.name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              accountEmail: Text(user.identifier, style: GoogleFonts.poppins()),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.lightGreen),
            ),

            // ---------- Drawer Items ----------
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(
                languageProvider.translate('dashboard'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherDashboardScreen(user: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(
                languageProvider.translate('ai_substitution'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AiSubstitution()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: Text(
                languageProvider.translate('ai_notes'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AiNoteScreen(canAdd: true, user: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(
                languageProvider.translate('leave_request'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LeaverequestPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: Text(
                languageProvider.translate('feedbacks'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen()),
                );
              },
            ),

            const Spacer(),

            // ---------- Logout Button ----------
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(
                    languageProvider.translate('logout'),
                    style: GoogleFonts.poppins(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Logged out",
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
