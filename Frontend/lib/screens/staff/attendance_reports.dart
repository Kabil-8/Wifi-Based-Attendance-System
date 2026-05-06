import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AttendanceReports extends StatefulWidget {
  const AttendanceReports({super.key});

  @override
  State<AttendanceReports> createState() => _AttendanceReportsState();
}

class _AttendanceReportsState extends State<AttendanceReports> {
  String selectedClass = "CSE – III A";
  String selectedSubject = "Data Structures";
  String reportType = "Overall Attendance";

  DateTime? fromDate;
  DateTime? toDate;

  bool isLoading = false;

  Map<String, dynamic>? summary;

  final List<String> classes = [
    "CSE – I A",
    "CSE – II A",
    "CSE – III A",
    "CSE – IV A",
  ];

  final List<String> subjects = [
    "Data Structures",
    "Operating Systems",
    "DBMS",
    "Computer Networks",
  ];

  final List<String> reportTypes = [
    "Overall Attendance",
    "Student Wise",
    "Date Wise",
    "Defaulters List",
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      setState(() => isLoading = true);

      final res = await ApiService.get(
        "/reports/summary"
        "?class=$selectedClass"
        "&subject=$selectedSubject"
        "&type=$reportType",
      );

      summary = res;

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      _showSnack("Failed to load summary");
    }
  }

  Future<void> _downloadReport(String type) async {
    try {
      _showSnack("Generating report...");

      await ApiService.post(
        "/reports/$type",
        body: {
          "class": selectedClass,
          "subject": selectedSubject,
          "reportType": reportType,
          "from": fromDate?.toIso8601String(),
          "to": toDate?.toIso8601String(),
        },
      );

      _showSnack("$type report generated");
    } catch (e) {
      _showSnack("Report failed");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFilterCard(),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildDownloadButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Column(
      children: [
        _dropdown("Class", selectedClass, classes, (v) {
          setState(() => selectedClass = v!);
          _loadSummary();
        }),
        const SizedBox(height: 12),
        _dropdown("Subject", selectedSubject, subjects, (v) {
          setState(() => selectedSubject = v!);
          _loadSummary();
        }),
        const SizedBox(height: 12),
        _dropdown("Report Type", reportType, reportTypes, (v) {
          setState(() => reportType = v!);
          _loadSummary();
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _dateBox("From", fromDate, () => _selectDate(true))),
            const SizedBox(width: 10),
            Expanded(child: _dateBox("To", toDate, () => _selectDate(false))),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    if (summary == null) {
      return const Text("No data");
    }

    return Column(
      children: [
        _summaryRow("Total Classes", summary!["total"]?.toString() ?? "0"),
        _summaryRow("Average %", "${summary!["average"] ?? 0}%"),
        _summaryRow(">=75%", summary!["above75"]?.toString() ?? "0"),
        _summaryRow("<75%", summary!["defaulters"]?.toString() ?? "0"),
      ],
    );
  }

  Widget _buildDownloadButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _downloadReport("pdf"),
          child: const Text("Download PDF"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _downloadReport("excel"),
          child: const Text("Download Excel"),
        ),
      ],
    );
  }

  Widget _dropdown(
      String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _summaryRow(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _dateBox(String label, DateTime? d, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          d == null ? "Select" : "${d.day}/${d.month}/${d.year}",
        ),
      ),
    );
  }

  Future<void> _selectDate(bool from) async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (p != null) {
      setState(() {
        if (from) {
          fromDate = p;
        } else {
          toDate = p;
        }
      });
      _loadSummary();
    }
  }
}
