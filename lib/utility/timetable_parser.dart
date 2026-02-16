import 'dart:io';
import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../model/timetable_model.dart';

class TimetableParser {
  /// Parse PDF file and return list of TimetableEntry objects
  /// Expected PDF format: Table with columns: Day, Period, Teacher Name, Subject, Class, Start Time, End Time
  static Future<List<TimetableEntry>> parsePdf(String pdfPath) async {
    try {
      // Load PDF document
      final File file = File(pdfPath);
      final PdfDocument document = PdfDocument(
        inputBytes: file.readAsBytesSync(),
      );

      // Extract text from all pages
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      print('DEBUG: Extracted PDF text length: ${text.length}');
      print(
        'DEBUG: First 500 chars: ${text.substring(0, text.length > 500 ? 500 : text.length)}',
      );

      // If text is empty, throw error
      if (text.trim().isEmpty) {
        throw Exception('PDF appears to be empty or contains only images');
      }

      // Split by lines and clean
      List<String> lines = text
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      print('DEBUG: Total lines found: ${lines.length}');

      List<TimetableEntry> entries = [];
      int skippedLines = 0;

      // Try to parse each line
      for (int i = 0; i < lines.length; i++) {
        var line = lines[i];

        // Skip header-like lines
        if (line.toLowerCase().contains('day') &&
            line.toLowerCase().contains('period')) {
          print('DEBUG: Skipping header line: $line');
          continue;
        }

        // Try different separation methods
        List<String> parts = [];

        // Method 1: Comma separated
        if (line.contains(',')) {
          parts = line.split(',').map((p) => p.trim()).toList();
          print('DEBUG: Line $i (comma): ${parts.length} parts');
        }
        // Method 2: Tab separated
        else if (line.contains('\t')) {
          parts = line
              .split('\t')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          print('DEBUG: Line $i (tab): ${parts.length} parts');
        }
        // Method 3: Multiple spaces (2+)
        else if (line.contains(RegExp(r'\s{2,}'))) {
          parts = line
              .split(RegExp(r'\s{2,}'))
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          print('DEBUG: Line $i (multi-space): ${parts.length} parts');
        }
        // Method 4: Single space (fallback for simple tables)
        else if (line.contains(' ')) {
          parts = line
              .split(' ')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          print('DEBUG: Line $i (single-space): ${parts.length} parts');
        }

        // Need at least 7 parts
        if (parts.length >= 7) {
          try {
            // Validate day name
            if (!isValidDay(parts[0])) {
              print('DEBUG: Invalid day: ${parts[0]}');
              skippedLines++;
              continue;
            }

            final entry = TimetableEntry(
              day: parts[0].trim(),
              period: int.parse(parts[1].trim()),
              teacherName: parts[2].trim(),
              subject: parts[3].trim(),
              className: parts[4].trim(),
              startTime: parts[5].trim(),
              endTime: parts[6].trim(),
              attendance: "Present",
            );
            entries.add(entry);
            print(
              'DEBUG: Successfully parsed entry: ${entry.teacherName} - ${entry.subject}',
            );
          } catch (e) {
            print('DEBUG: Error parsing line $i: $e');
            print('DEBUG: Parts: $parts');
            skippedLines++;
            continue;
          }
        } else {
          print('DEBUG: Line $i has only ${parts.length} parts, need 7');
          skippedLines++;
        }
      }

      print('DEBUG: Total entries parsed: ${entries.length}');
      print('DEBUG: Total lines skipped: $skippedLines');

      if (entries.isEmpty) {
        throw Exception(
          'No valid timetable entries found in PDF. '
          'Parsed ${lines.length} lines, skipped $skippedLines. '
          'Please ensure PDF has 7 columns: Day, Period, Teacher Name, Subject, Class, Start Time, End Time',
        );
      }

      return entries;
    } catch (e) {
      print('DEBUG: PDF parsing error: $e');
      throw Exception('Error parsing PDF: $e');
    }
  }

  /// Parse CSV content and return list of TimetableEntry objects
  /// Expected CSV format: Day,Period,Teacher Name,Subject,Class,Start Time,End Time
  static Future<List<TimetableEntry>> parseCsv(String csvContent) async {
    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvContent,
      );

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header row (first row)
      final dataRows = rows.skip(1);

      List<TimetableEntry> entries = [];

      for (var row in dataRows) {
        if (row.length < 7) {
          continue; // Skip incomplete rows
        }

        try {
          final entry = TimetableEntry(
            day: row[0].toString().trim(),
            period: int.parse(row[1].toString().trim()),
            teacherName: row[2].toString().trim(),
            subject: row[3].toString().trim(),
            className: row[4].toString().trim(),
            startTime: row[5].toString().trim(),
            endTime: row[6].toString().trim(),
            attendance: "Present", // Default to present
          );
          entries.add(entry);
        } catch (e) {
          // Skip rows with parsing errors
          continue;
        }
      }

      if (entries.isEmpty) {
        throw Exception('No valid timetable entries found in CSV');
      }

      return entries;
    } catch (e) {
      throw Exception('Error parsing CSV: $e');
    }
  }

  /// Validate day name
  static bool isValidDay(String day) {
    const validDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return validDays.contains(day);
  }

  /// Get list of all days in order
  static List<String> getDaysOfWeek() {
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
  }
}
