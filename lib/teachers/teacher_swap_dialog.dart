import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/timetable_model.dart';
import '../service/timetable_database_service.dart';
import '../service/database_service.dart';
import '../model/notification_model.dart';

class TeacherSwapDialog extends StatefulWidget {
  final TimetableEntry absentEntry;
  final String selectedDay;

  const TeacherSwapDialog({
    super.key,
    required this.absentEntry,
    required this.selectedDay,
  });

  @override
  State<TeacherSwapDialog> createState() => _TeacherSwapDialogState();
}

class _TeacherSwapDialogState extends State<TeacherSwapDialog> {
  final TimetableDatabaseService _dbService = TimetableDatabaseService();
  final TextEditingController _customNameController = TextEditingController();
  List<TimetableEntry> availableTeachers = [];
  TimetableEntry? selectedTeacher;
  bool isLoading = true;
  bool useCustomName = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableTeachers();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTeachers() async {
    try {
      final allEntries = await _dbService.getEntriesByDay(widget.selectedDay);

      // Filter to get only present teachers (excluding the absent one)
      final available = allEntries
          .where(
            (entry) =>
                entry.attendance == "Present" &&
                entry.teacherName != widget.absentEntry.teacherName,
          )
          .toList();

      setState(() {
        availableTeachers = available;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading teachers: $e')));
      }
    }
  }

  Future<void> _performSwap() async {
    String? replacementName;

    if (useCustomName) {
      // Use custom name
      if (_customNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a teacher name')),
        );
        return;
      }
      replacementName = _customNameController.text.trim();
    } else {
      // Use selected teacher
      if (selectedTeacher == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a teacher or enter a custom name'),
          ),
        );
        return;
      }
    }

    try {
      if (useCustomName) {
        // Just update the absent teacher's name
        await _dbService.assignTeacher(
          widget.absentEntry.id!,
          replacementName!,
        );

        // 🔹 Trigger Notification (using main DatabaseService)
        // Note: Assuming DatabaseService is imported or I need to import it.
        // TeacherSwapDialog uses TimetableDatabaseService, but notifications are in main DB.
        // I need to import DatabaseService and NotificationModel.
        await DatabaseService().insertNotification(
          NotificationModel(
            title: "Teacher Substituted",
            message:
                "$replacementName assigned to ${widget.absentEntry.subject} (${widget.absentEntry.className})",
            date: DateTime.now().toString(),
            type: "substitution",
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Assigned $replacementName to ${widget.absentEntry.subject}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Swap with existing teacher
        await _dbService.swapTeachers(
          widget.absentEntry.id!,
          selectedTeacher!.id!,
        );

        // 🔹 Trigger Notification
        await DatabaseService().insertNotification(
          NotificationModel(
            title: "Teacher Swapped",
            message:
                "${selectedTeacher!.teacherName} swapped with ${widget.absentEntry.teacherName} for ${widget.absentEntry.subject}",
            date: DateTime.now().toString(),
            type: "substitution",
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully swapped ${widget.absentEntry.teacherName} with ${selectedTeacher!.teacherName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing swap: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Substitute Teacher',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Absent Teacher Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Absent Teacher',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Name',
                            widget.absentEntry.teacherName,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.book_outlined,
                            'Subject',
                            widget.absentEntry.subject,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow(
                                  Icons.access_time,
                                  'Time',
                                  '${widget.absentEntry.startTime} - ${widget.absentEntry.endTime}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow(
                                  Icons.class_outlined,
                                  'Class',
                                  widget.absentEntry.className,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoRow(
                                  Icons.calendar_today_outlined,
                                  'Period',
                                  widget.absentEntry.period.toString(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Selection Mode
                    Text(
                      "Substitution Method",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade200,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              "Select Teacher",
                              !useCustomName,
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              "Custom Name",
                              useCustomName,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content based on mode
                    if (useCustomName)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enter Name",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customNameController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Sarah Johnson',
                              prefixIcon: Icon(
                                Icons.person_add_outlined,
                                color: primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Available Teachers",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade200,
                            ),
                          ),
                          if (!isLoading)
                            Text(
                              "${availableTeachers.length} found",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (availableTeachers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.shade200.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade800,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No other teachers available",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Try entering a custom name instead.",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: availableTeachers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final teacher = availableTeachers[index];
                              final isSelected =
                                  selectedTeacher?.id == teacher.id;
                              return InkWell(
                                onTap: () =>
                                    setState(() => selectedTeacher = teacher),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSelected
                                            ? primaryColor
                                            : Colors.grey.shade200,
                                        radius: 16,
                                        child: Text(
                                          teacher.teacherName[0].toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              teacher.teacherName,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "${teacher.subject} • ${teacher.className}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: primaryColor,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (useCustomName &&
                                  _customNameController.text
                                      .trim()
                                      .isNotEmpty) ||
                              (!useCustomName && selectedTeacher != null)
                          ? _performSwap
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        useCustomName ? 'Assign' : 'Confirm Swap',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          useCustomName = text == "Custom Name";
          if (useCustomName)
            selectedTeacher = null;
          else
            _customNameController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
