import 'package:aiworkflowautomation/model/leave_request_model.dart';
import 'package:aiworkflowautomation/service/database_service.dart';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> {
  String _leaveType = 'Full Day';
  DateTime? _selectedDate;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (_nameController.text.isEmpty ||
        _selectedDate == null ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final request = LeaveRequestModel(
      name: _nameController.text,
      date: _selectedDate.toString().split(' ')[0],
      type: _leaveType,
      reason: _reasonController.text,
    );

    await _dbService.insertLeaveRequest(request);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave Request Submitted Successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);

    final double maxWidth = isMobile ? double.infinity : 500;
    final double fieldSpacing = isMobile ? 12 : 16;
    final double buttonHeight = isMobile ? 50 : 56;
    final double titleSize = isMobile ? 18 : 20;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: Text(
          "Leave Request",
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
                _buildField(hint: "Enter Name", controller: _nameController),

                SizedBox(height: fieldSpacing),

                /// 🔹 DATE PICKER
                DateTimeField(
                  decoration: _inputDecoration("Select Date"),
                  mode: DateTimeFieldPickerMode.date,
                  onChanged: (DateTime? value) {
                    _selectedDate = value;
                  },
                ),

                SizedBox(height: fieldSpacing),

                /// 🔹 LEAVE TYPE
                DropdownButtonFormField<String>(
                  value: _leaveType,
                  decoration: _inputDecoration("Select Leave Type"),
                  items: const [
                    DropdownMenuItem(
                      value: 'Full Day',
                      child: Text('Full Day'),
                    ),
                    DropdownMenuItem(
                      value: 'Half Day',
                      child: Text('Half Day'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _leaveType = value!);
                  },
                ),

                SizedBox(height: fieldSpacing),

                /// 🔹 REASON
                TextField(
                  controller: _reasonController,
                  maxLines: 5,
                  decoration: _inputDecoration("Reason for Leave"),
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
                    onPressed: _submitRequest,
                    child: Text(
                      "Submit",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Common Input Decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  /// 🔹 Simple Text Field
  Widget _buildField({
    required String hint,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint),
    );
  }
}
