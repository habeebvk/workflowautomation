import 'package:aiworkflowautomation/model/leave_request_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaverequestPage extends StatefulWidget {
  const LeaverequestPage({super.key});

  @override
  State<LeaverequestPage> createState() => _LeaverequestPageState();
}

class _LeaverequestPageState extends State<LeaverequestPage> {
  final DatabaseService _dbService = DatabaseService();
  List<LeaveRequestModel> _leaveRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoading = true);
    final requests = await _dbService.getPendingLeaveRequests();
    setState(() {
      _leaveRequests = requests;
      _isLoading = false;
    });
  }

  Future<void> _approveRequest(int id) async {
    await _dbService.updateLeaveRequestStatus(id, 'approved');
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request approved')));
      _loadLeaveRequests();
    }
  }

  Future<void> _declineRequest(int id) async {
    await _dbService.updateLeaveRequestStatus(id, 'declined');
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request declined')));
      _loadLeaveRequests();
    }
  }

  Widget _leaveCard({
    required LeaveRequestModel request,
    required bool isMobile,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isMobile ? 14 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// 🔹 USER INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${request.date} • ${request.type}',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 ACTION BUTTONS
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.check,
                      color: Colors.green,
                      onTap: () => _approveRequest(request.id!),
                      isMobile: isMobile,
                    ),
                    const SizedBox(width: 10),
                    _actionButton(
                      icon: Icons.close,
                      color: Colors.red,
                      onTap: () => _declineRequest(request.id!),
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${request.reason}',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? 36 : 40,
      height: isMobile ? 36 : 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: isMobile ? 18 : 20),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double maxWidth = isMobile ? double.infinity : 700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: Text(
          "Leave Requests",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _leaveRequests.isEmpty
            ? Center(
                child: Text(
                  'No pending leave requests',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Container(
                  width: maxWidth,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ..._leaveRequests.map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _leaveCard(
                            request: request,
                            isMobile: isMobile,
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
