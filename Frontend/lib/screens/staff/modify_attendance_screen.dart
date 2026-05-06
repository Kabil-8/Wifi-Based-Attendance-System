import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/staff_provider.dart';

class ModifyAttendanceScreen extends StatefulWidget {
  const ModifyAttendanceScreen({super.key});

  @override
  State<ModifyAttendanceScreen> createState() =>
      _ModifyAttendanceScreenState();
}

class _ModifyAttendanceScreenState extends State<ModifyAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final String classId = "CSE3A";
  final String className = "CSE – III A";
  final String subjectName = "Data Structures";

  final List<String> statusOptions = ["Present", "Absent", "OD"];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStudents(classId);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Modify Attendance"),
        backgroundColor: Colors.indigo,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        ),
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(provider),
      ),
    );
  }

  Widget _buildContent(StaffProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(provider),
          const SizedBox(height: 20),
          Expanded(child: _buildStudentList(provider)),
          const SizedBox(height: 10),
          _buildButtons(provider),
        ],
      ),
    );
  }

  Widget _buildHeader(StaffProvider provider) {
    final presentCount = provider.students
        .where((s) => s["status"] == "Present")
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.class_, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(className,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subjectName),
              Text("${provider.students.length} Students"),
              Text("$presentCount Present"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStudentList(StaffProvider provider) {
    return ListView.separated(
      itemCount: provider.students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final student = provider.students[index];
        return _studentTile(index, student);
      },
    );
  }

  Widget _studentTile(int index, Map<String, dynamic> student) {
    final color = _statusColor(student["status"]);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Text("${index + 1}",
                style: TextStyle(color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(student["roll"]),
              ],
            ),
          ),
          DropdownButton<String>(
            value: student["status"],
            items: statusOptions
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                context.read<StaffProvider>()
                    .students[index]["status"] = val;
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildButtons(StaffProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await provider.saveAttendance(provider.students);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Saved to backend")),
              );
            },
            child: const Text("Save Changes"),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Present":
        return Colors.green;
      case "Absent":
        return Colors.red;
      case "OD":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
