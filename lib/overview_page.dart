import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/home_screen.dart';
import 'package:aiworkflowautomation/model/notification_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final notifications = await DatabaseService().getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    bool isMobile,
    ThemeData theme,
  ) {
    final colors = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: isMobile ? 40 : 46,
            width: isMobile ? 40 : 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 11 : 12,
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile(String title, bool isMobile, ThemeData theme) {
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isMobile ? 18 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 15 : 16,
          color: colors.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final double maxWidth = isMobile ? double.infinity : 900;
    final double horizontalPadding = isMobile ? 16 : 24;

    return Scaffold(
      drawer: AppDrawer(user: widget.user),
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: maxWidth,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// 🔹 SUMMARY
                Text(
                  'Summary',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 STATS GRID
                StreamBuilder<Map<String, int>>(
                  stream: DatabaseService().statsStream,
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? {};
                    final studentCount = stats['students'] ?? 0;
                    final noteCount = stats['notes'] ?? 0;
                    final substitutionCount = stats['substitutions'] ?? 0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (Responsive.isDesktop(context)) {
                          crossAxisCount = 4;
                        } else if (isTablet) {
                          crossAxisCount = 3;
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: isMobile ? 2.4 : 2.8,
                          children: [
                            _buildStatCard(
                              'Total Students',
                              studentCount.toString(),
                              Icons.people,
                              Colors.indigo,
                              isMobile,
                              theme,
                            ),
                            _buildStatCard(
                              'Notes Published',
                              noteCount.toString(),
                              Icons.note,
                              Colors.green,
                              isMobile,
                              theme,
                            ),
                            _buildStatCard(
                              'AI Jobs',
                              '12 Running',
                              Icons.smart_toy,
                              Colors.deepPurple,
                              isMobile,
                              theme,
                            ),
                            _buildStatCard(
                              'Substitutions',
                              substitutionCount.toString(),
                              Icons.swap_horiz,
                              Colors.orange,
                              isMobile,
                              theme,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                // Initial data loader
                FutureBuilder(
                  future: DatabaseService().broadcastStats(),
                  builder: (context, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                /// 🔹 RECENT ACTIVITY
                const SizedBox(height: 25),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),
                const SizedBox(height: 12),

                if (_notifications.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No recent activity",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ..._notifications.map((notification) {
                    IconData icon;
                    Color color;
                    switch (notification.type) {
                      case 'note':
                        icon = Icons.note_add;
                        color = Colors.blue;
                        break;
                      case 'activity':
                        icon = Icons.post_add;
                        color = Colors.green;
                        break;
                      case 'answer':
                        icon = Icons.question_answer;
                        color = Colors.orange;
                        break;
                      case 'substitution':
                        icon = Icons.swap_horiz;
                        color = Colors.purple;
                        break;
                      default:
                        icon = Icons.notifications;
                        color = Colors.grey;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colors.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.date.split('.')[0],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 10),

                /// 🔹 FEATURES
                Text(
                  'Features',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),

                const SizedBox(height: 12),

                _featureTile("AI Automation", isMobile, theme),
                const SizedBox(height: 10),
                _featureTile("AI Substitution", isMobile, theme),
                const SizedBox(height: 10),
                _featureTile("AI One-to-one Tutor", isMobile, theme),
                const SizedBox(height: 10),
                _featureTile("AI Generated Summaries", isMobile, theme),
                const SizedBox(height: 10),
                _featureTile("Multilingual Support", isMobile, theme),
                const SizedBox(height: 10),
                _featureTile("Attendance Request", isMobile, theme),
                const SizedBox(height: 10),
                _featureTile("Automated Scheduling", isMobile, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
