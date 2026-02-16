import 'dart:io';
import 'package:aiworkflowautomation/utility/screen_utility.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../model/timetable_model.dart';
import '../service/timetable_database_service.dart';
import '../utility/timetable_parser.dart';
import 'teacher_swap_dialog.dart';

class AiSubstitution extends StatefulWidget {
  const AiSubstitution({super.key});

  @override
  State<AiSubstitution> createState() => _AiSubstitutionState();
}

class _AiSubstitutionState extends State<AiSubstitution> {
  final TimetableDatabaseService _dbService = TimetableDatabaseService();

  List<TimetableEntry> currentDayEntries = [];
  String selectedDay = 'Monday';
  bool isLoading = true;
  bool hasUploadedData = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadData();
  }

  Future<void> _checkAndLoadData() async {
    setState(() => isLoading = true);

    final hasData = await _dbService.hasData();
    setState(() => hasUploadedData = hasData);

    if (hasData) {
      await _loadTimetableForDay(selectedDay);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTimetableForDay(String day) async {
    setState(() => isLoading = true);

    try {
      final entries = await _dbService.getEntriesByDay(day);
      setState(() {
        currentDayEntries = entries;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading timetable: $e')));
      }
    }
  }

  Future<void> _uploadTimetable({bool uploadAllDays = true}) async {
    try {
      // Pick CSV or PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'pdf'],
      );

      if (result == null) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Get file path and extension
      final filePath = result.files.single.path!;
      final fileExtension = result.files.single.extension?.toLowerCase();

      // Parse based on file type
      List<TimetableEntry> entries;
      if (fileExtension == 'pdf') {
        entries = await TimetableParser.parsePdf(filePath);
      } else if (fileExtension == 'csv') {
        final file = File(filePath);
        final csvContent = await file.readAsString();
        entries = await TimetableParser.parseCsv(csvContent);
      } else {
        throw Exception(
          'Unsupported file format. Please upload CSV or PDF file.',
        );
      }

      // If uploading for current day only, filter entries
      if (!uploadAllDays) {
        // 1. Try to find entries for the exact selected day
        var dayEntries = entries.where((e) => e.day == selectedDay).toList();

        if (dayEntries.isEmpty) {
          // 2. If no entries for selected day, check if there are ANY entries
          if (entries.isNotEmpty) {
            // Get the first available day from the file
            final firstAvailableDay = entries.first.day;

            // Take entries from that day
            final sourceEntries = entries
                .where((e) => e.day == firstAvailableDay)
                .toList();

            // Map them to the selected day
            dayEntries = sourceEntries
                .map((e) => e.copyWith(day: selectedDay))
                .toList();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No entries found for $selectedDay. Used data from $firstAvailableDay instead.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }

        if (dayEntries.isEmpty) {
          throw Exception(
            'No valid timetable entries found in the uploaded file.',
          );
        }

        // Update the main entries list to be just the filtered/mapped ones
        entries = dayEntries;

        // Delete only current day's data
        await _dbService.deleteEntriesByDay(selectedDay);
      } else {
        // Delete all existing data
        await _dbService.deleteAllEntries();
      }

      // Insert new entries
      await _dbService.insertMultipleEntries(entries);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Reload data
      await _checkAndLoadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadAllDays
                  ? 'Successfully uploaded ${entries.length} timetable entries'
                  : 'Successfully uploaded ${entries.length} entries for $selectedDay',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading timetable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTimetable({bool deleteAllDays = true}) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Delete',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          deleteAllDays
              ? 'Are you sure you want to delete the entire timetable for all 7 days? This action cannot be undone.'
              : 'Are you sure you want to delete the timetable for $selectedDay? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Delete data
      if (deleteAllDays) {
        await _dbService.deleteAllEntries();
      } else {
        await _dbService.deleteEntriesByDay(selectedDay);
      }

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Reload data
      await _checkAndLoadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteAllDays
                  ? 'Successfully deleted all timetable data'
                  : 'Successfully deleted timetable for $selectedDay',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading if open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting timetable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAttendance(TimetableEntry entry) async {
    final newAttendance = entry.attendance == "Present" ? "Absent" : "Present";

    try {
      await _dbService.updateAttendance(entry.id!, newAttendance);
      await _loadTimetableForDay(selectedDay);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.teacherName} marked as $newAttendance'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating attendance: $e')),
        );
      }
    }
  }

  Future<void> _showSwapDialog(TimetableEntry absentEntry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          TeacherSwapDialog(absentEntry: absentEntry, selectedDay: selectedDay),
    );

    // Reload if swap was successful
    if (result == true) {
      await _loadTimetableForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double maxWidth = isMobile ? double.infinity : 900;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Substitution",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Timetable',
            onSelected: (value) {
              if (value == 'all') {
                _uploadTimetable(uploadAllDays: true);
              } else if (value == 'current') {
                _uploadTimetable(uploadAllDays: false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Upload All Days'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'current',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Upload Current Day Only'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Timetable',
            onSelected: (value) {
              if (value == 'all') {
                _deleteTimetable(deleteAllDays: true);
              } else if (value == 'current') {
                _deleteTimetable(deleteAllDays: false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Days'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'current',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Delete Current Day'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadTimetableForDay(selectedDay),
          ),
        ],
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
                  // Upload prompt if no data
                  if (!hasUploadedData && !isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Timetable Data',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload a CSV or PDF file to get started',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _uploadTimetable,
                            icon: const Icon(Icons.upload),
                            label: Text(
                              'Upload Timetable',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Day selector
                  if (hasUploadedData) ...[
                    Text(
                      "Select Day",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TimetableParser.getDaysOfWeek().map((day) {
                        final isSelected = day == selectedDay;
                        return ChoiceChip(
                          label: Text(
                            day,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedDay = day);
                              _loadTimetableForDay(day);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Timetable header
                    Text(
                      "$selectedDay's Timetable",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Table Card
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (currentDayEntries.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No timetable entries for $selectedDay',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _uploadTimetable(uploadAllDays: false),
                              icon: const Icon(Icons.upload_file),
                              label: Text(
                                'Upload $selectedDay Timetable',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              theme.colorScheme.primary.withOpacity(0.2),
                            ),
                            columnSpacing: isMobile ? 20 : 30,
                            dataRowHeight: isMobile ? 52 : 58,
                            headingTextStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 13 : 15,
                              color: theme.colorScheme.onSurface,
                            ),
                            dataTextStyle: GoogleFonts.poppins(
                              fontSize: isMobile ? 12 : 14,
                              color: theme.colorScheme.onSurface,
                            ),
                            columns: const [
                              DataColumn(label: Text("Period")),
                              DataColumn(label: Text("Teacher")),
                              DataColumn(label: Text("Subject")),
                              DataColumn(label: Text("Class")),
                              DataColumn(label: Text("Time")),
                              DataColumn(label: Text("Status")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: currentDayEntries.map((entry) {
                              final isAbsent = entry.attendance == "Absent";
                              return DataRow(
                                color: MaterialStateProperty.all(
                                  isAbsent ? Colors.red.shade50 : null,
                                ),
                                cells: [
                                  DataCell(
                                    Text(
                                      entry.period.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      entry.teacherName,
                                      style: TextStyle(
                                        color: isAbsent ? Colors.red : null,
                                        fontWeight: isAbsent
                                            ? FontWeight.w600
                                            : null,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(entry.subject)),
                                  DataCell(Text(entry.className)),
                                  DataCell(
                                    Text('${entry.startTime}-${entry.endTime}'),
                                  ),
                                  DataCell(
                                    Chip(
                                      label: Text(
                                        entry.attendance,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: isAbsent
                                          ? Colors.red
                                          : Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isAbsent
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            size: 20,
                                          ),
                                          tooltip: isAbsent
                                              ? 'Mark Present'
                                              : 'Mark Absent',
                                          onPressed: () =>
                                              _toggleAttendance(entry),
                                        ),
                                        if (isAbsent)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.swap_horiz,
                                              size: 20,
                                            ),
                                            tooltip: 'Find Substitute',
                                            color: theme.colorScheme.primary,
                                            onPressed: () =>
                                                _showSwapDialog(entry),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Instructions removed
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
