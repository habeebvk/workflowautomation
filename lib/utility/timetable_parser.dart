import 'dart:io';
import 'dart:ui';
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

      // Pre-process lines: sometimes PDF extraction puts each cell on a new line
      // If we see a day name followed by single-word lines, we should try to group them.
      List<List<String>> reconstructedRows = [];
      for (int i = 0; i < lines.length; i++) {
        var line = lines[i];

        // Skip title/header
        if (line.toUpperCase().contains('CLASS TIMETABLE') ||
            (line.toLowerCase().contains('day') &&
                line.toLowerCase().contains('period'))) {
          continue;
        }

        List<String> currentParts = _splitLine(line);

        // If this part starts with a valid day...
        if (currentParts.isNotEmpty && isValidDay(currentParts[0])) {
          // If it already has enough parts, it's a full line
          if (currentParts.length >= 6) {
            reconstructedRows.add(currentParts);
          }
          // Otherwise, it might be the start of a multi-line row
          else {
            List<String> fullRow = List.from(currentParts);
            int j = i + 1;
            while (j < lines.length && fullRow.length < 6) {
              var nextLine = lines[j];
              var nextParts = _splitLine(nextLine);

              // If next line starts with a day, it's a new row, so stop here
              if (nextParts.isNotEmpty && isValidDay(nextParts[0])) break;

              fullRow.addAll(nextParts);
              j++;
            }
            if (fullRow.length >= 6) {
              reconstructedRows.add(fullRow);
              i = j - 1; // Skip the lines we consumed
            } else {
              skippedLines++;
            }
          }
        } else {
          skippedLines++;
        }
      }

      // Parse the reconstructed rows
      for (var parts in reconstructedRows) {
        try {
          String day = parts[0];
          int period = int.parse(parts[1]);
          String teacher = parts[2];
          String subject = parts[3];
          String className = parts[4];
          String startTime = "";
          String endTime = "";

          if (parts.length == 7 && !parts[6].contains('-')) {
            // Legacy 7-column format
            startTime = parts[5];
            endTime = parts[6];
          } else {
            // New 6-column format or combined time
            String timePart = parts.sublist(5).join(" ");

            if (timePart.contains('-')) {
              var timeSplit = timePart.split('-').map((s) => s.trim()).toList();
              if (timeSplit.length >= 2) {
                startTime = timeSplit[0];
                endTime = timeSplit[1];
              }
            } else if (parts.length >= 7) {
              startTime = parts[5];
              endTime = parts[6];
            }
          }

          if (startTime.isNotEmpty) {
            final entry = TimetableEntry(
              day: day,
              period: period,
              teacherName: teacher,
              subject: subject,
              className: className,
              startTime: startTime,
              endTime: endTime,
              attendance: "Present",
            );
            entries.add(entry);
          } else {
            skippedLines++;
          }
        } catch (e) {
          skippedLines++;
        }
      }

      if (entries.isEmpty) {
        throw Exception(
          'No valid timetable entries found in PDF. '
          'Parsed ${lines.length} lines, skipped $skippedLines. '
          'Please ensure PDF has 6 columns: Day, Period, Teacher, Subject, Class, Time',
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

  /// Generate a sample PDF file and return its bytes
  static List<int> generateSamplePdf() {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a new page to the document
    final PdfPage page = document.pages.add();

    // Create a font
    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.timesRoman,
      20,
      style: PdfFontStyle.bold,
    );
    final PdfFont tableFont = PdfStandardFont(PdfFontFamily.timesRoman, 12);

    // Draw Title
    page.graphics.drawString(
      'CLASS TIMETABLE',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Create a PDF grid
    final PdfGrid grid = PdfGrid();

    // Add columns to the grid
    grid.columns.add(count: 6);

    // Set borderless style
    final PdfPen transparentPen = PdfPen(PdfColor(255, 255, 255), width: 0);
    grid.style.borderOverlapStyle = PdfBorderOverlapStyle.overlap;

    // Add headers
    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'Day';
    header.cells[1].value = 'Period';
    header.cells[2].value = 'Teacher';
    header.cells[3].value = 'Subject';
    header.cells[4].value = 'Class';
    header.cells[5].value = 'Time';

    // Apply font and transparent borders to all cells
    for (int i = 0; i < grid.headers.count; i++) {
      for (int j = 0; j < grid.headers[i].cells.count; j++) {
        header.cells[j].style.font = tableFont;
        grid.headers[i].cells[j].style.borders.all = transparentPen;
      }
    }

    // Add sample rows from the screenshot provided by user
    _addSampleRow(
      grid,
      transparentPen,
      tableFont,
      'Monday',
      '1',
      'Sharina',
      'Java',
      '10A',
      '9:00 - 9:45',
    );
    _addSampleRow(
      grid,
      transparentPen,
      tableFont,
      'Monday',
      '2',
      'Arun',
      'Python',
      '10B',
      '9:45 - 10:30',
    );
    _addSampleRow(
      grid,
      transparentPen,
      tableFont,
      'Monday',
      '3',
      'Divya',
      'C Programming',
      '10A',
      '10:45 - 11:30',
    );

    // Draw the grid to the page, starting below the title
    grid.draw(page: page, bounds: const Rect.fromLTWH(0, 80, 0, 0));

    // Save the document as bytes
    final List<int> bytes = document.saveSync();

    // Dispose the document
    document.dispose();

    return bytes;
  }

  static void _addSampleRow(
    PdfGrid grid,
    PdfPen borderPen,
    PdfFont font,
    String day,
    String period,
    String teacher,
    String subject,
    String className,
    String time,
  ) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = day;
    row.cells[1].value = period;
    row.cells[2].value = teacher;
    row.cells[3].value = subject;
    row.cells[4].value = className;
    row.cells[5].value = time;

    // Apply transparent border and font
    for (int i = 0; i < row.cells.count; i++) {
      row.cells[i].style.font = font;
      row.cells[i].style.borders.all = borderPen;
    }
  }

  /// Helper to split line into parts using various separators
  static List<String> _splitLine(String line) {
    if (line.contains(',')) {
      return line.split(',').map((p) => p.trim()).toList();
    } else if (line.contains('\t')) {
      return line
          .split('\t')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    } else if (line.contains(RegExp(r'\s{2,}'))) {
      return line
          .split(RegExp(r'\s{2,}'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    } else if (line.contains(' ')) {
      return line
          .split(' ')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    }
    return [line.trim()];
  }
}
