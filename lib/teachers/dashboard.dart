import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/model/user_model.dart';
import 'package:aiworkflowautomation/home_screen.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final UserModel user;
  const TeacherDashboardScreen({super.key, required this.user});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isMobile ? 18 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
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
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);
    final double maxWidth = isMobile ? double.infinity : 900;
    final theme = Theme.of(context);

    return Scaffold(
      drawer: AppDrawer(user: widget.user),
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.lightGreen,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: maxWidth,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),

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

                  Text(
                    'Features',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
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
      ),
    );
  }
}
