import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/feedback_page.dart';
import 'package:aiworkflowautomation/leave_request.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/controller/language_provider.dart';
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:aiworkflowautomation/ai_workflow.dart';
import 'package:aiworkflowautomation/login_screen.dart';
import 'package:aiworkflowautomation/overview_page.dart';
import 'package:aiworkflowautomation/theme/theme_provider.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isMobile = Responsive.isMobile(context);
    final double maxWidth = isMobile ? double.infinity : 900;

    return Scaffold(
      drawer: AppDrawer(user: widget.user),
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
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  languageProvider.translate('recent_activity'),
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                StreamBuilder<List<NotificationModel>>(
                  stream: DatabaseService().notificationsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Fallback to FutureBuilder for initial load if stream is empty
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
          child: _activityCard(
            title: notification.title,
            time: notification.date.split('.')[0],
            icon: icon,
            color: color,
            isMobile: isMobile,
            onTap: () {
              // Add navigation logic if needed
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _activityCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required bool isMobile,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isMobile ? 70 : 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isMobile ? 15 : 16,
                  ),
                ),
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
}

class AppDrawer extends StatelessWidget {
  final UserModel user;
  const AppDrawer({super.key, required this.user});

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
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
              accountEmail: Text(
                user.identifier,
                style: GoogleFonts.poppins(fontSize: isMobile ? 13 : 14),
              ),
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
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(
                languageProvider.translate('dashboard'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () => _open(context, AdminDashboardScreen(user: user)),
            ),
            ListTile(
              leading: const Icon(Icons.note), // Changed icon to match notes
              title: Text(
                languageProvider.translate('ai_notes'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () => _open(context, AiNoteScreen(user: user)),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(
                languageProvider.translate('leave_request'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () => _open(context, const LeaveRequest()),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: Text(
                languageProvider.translate('feedbacks'),
                style: GoogleFonts.poppins(),
              ),
              onTap: () => _open(context, const FeedbackPage()),
            ),
            const Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return SwitchListTile(
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: Text(
                    themeProvider.isDarkMode ? "Dark Mode" : "Light Mode",
                    style: GoogleFonts.poppins(),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(12),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
