import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/staff_provider.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Attendance App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Modern Indigo
            primary: const Color(0xFF6366F1),
            secondary: const Color(0xFF8B5CF6),
            surface: Colors.white,
            background: const Color(0xFFF8FAFC), // Ultra-light slate
          ),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
          ),
        ),
        initialRoute: Routes.login,
        onGenerateRoute: (settings) {
          // You could use a custom transition here if needed
          return MaterialPageRoute(
            builder: (context) => Routes.routes[settings.name]!(context),
          );
        },
      ),
    );
  }
}
