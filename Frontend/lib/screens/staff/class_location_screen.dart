import 'package:flutter/material.dart';

class ClassLocationScreen extends StatefulWidget {
  const ClassLocationScreen({super.key});

  @override
  State<ClassLocationScreen> createState() => _ClassLocationScreenState();
}

class _ClassLocationScreenState extends State<ClassLocationScreen>
    with SingleTickerProviderStateMixin {
  String selectedClass = "CSE – III A";
  String selectedSubject = "Data Structures";

  final roomController = TextEditingController(text: "A403");
  final wifiController = TextEditingController(text: "MCET-A403");

  final _formKey = GlobalKey<FormState>();

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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
    _slideAnimation =
        Tween<double>(begin: 30, end: 0).animate(_animationController);
    _scaleAnimation =
        Tween<double>(begin: 0.9, end: 1).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    roomController.dispose();
    wifiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ---------- SAVE FUNCTION (CONNECT API LATER HERE) ----------
  void _saveLocation() {
    if (!_formKey.currentState!.validate()) return;

    final room = roomController.text.trim();
    final wifi = wifiController.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Saved: $selectedClass | $selectedSubject | Room $room | WiFi $wifi",
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Location Setup"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _classSubjectCard(),
              const SizedBox(height: 24),
              _locationCard(),
              const SizedBox(height: 30),
              _saveButton(),
              const SizedBox(height: 20),
              _infoBox(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- CLASS + SUBJECT ----------
  Widget _classSubjectCard() {
    return _card(
      title: "Class Details",
      icon: Icons.school,
      color: Colors.indigo,
      children: [
        _dropdown(
          label: "Class",
          value: selectedClass,
          items: classes,
          onChanged: (v) => setState(() => selectedClass = v),
        ),
        const SizedBox(height: 16),
        _dropdown(
          label: "Subject",
          value: selectedSubject,
          items: subjects,
          onChanged: (v) => setState(() => selectedSubject = v),
        ),
      ],
    );
  }

  // ---------- LOCATION ----------
  Widget _locationCard() {
    return _card(
      title: "Class Location (Wi-Fi Based)",
      icon: Icons.location_on,
      color: Colors.green,
      children: [
        TextFormField(
          controller: roomController,
          decoration: const InputDecoration(
            labelText: "Room Number",
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? "Enter room number" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: wifiController,
          decoration: const InputDecoration(
            labelText: "Wi-Fi SSID",
            border: OutlineInputBorder(),
            helperText: "Only this Wi-Fi can mark attendance",
          ),
          validator: (v) =>
              v == null || v.isEmpty ? "Enter Wi-Fi SSID" : null,
        ),
      ],
    );
  }

  // ---------- SAVE BUTTON ----------
  Widget _saveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _saveLocation,
        icon: const Icon(Icons.save),
        label: const Text("Save Class Location"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ---------- INFO ----------
  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Students connected to this Wi-Fi during class hours will be marked present automatically.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- COMMON CARD ----------
  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ---------- DROPDOWN ----------
  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}
