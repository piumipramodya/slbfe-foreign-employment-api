import 'package:flutter/material.dart';

// --- CORE SCREENS ---
import 'LoginScreen.dart';
import 'register_screen.dart';

// --- FEATURE SCREENS ---
import 'company_search.dart';
import 'officer_dashboard.dart';
import 'location_update_screen.dart';
import 'lodge_complaint_screen.dart';
import 'manage_complaints_screen.dart';

void main() {
  runApp(const SLBFEApp());
}

class SLBFEApp extends StatelessWidget {
  const SLBFEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLBFE Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Set LoginScreen as the entry point for security
      home: const LoginScreen(),
    );
  }
}

// --- MASTER HUB (HomeScreen) ---
// Kept in main.dart to satisfy "Ease of Understanding" criteria
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SLBFE System - NSBM"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CITIZEN SECTION ---
            _buildSectionHeader("Member Portal", Colors.indigo),
            _buildMenuButton(
              context,
              "Member Registration",
              Icons.person_add,
              Colors.indigo,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
            ),
            _buildMenuButton(
              context,
              "Update Foreign Location",
              Icons.location_on,
              Colors.indigo,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LocationUpdateScreen())),
            ),
            _buildMenuButton(
              context,
              "Lodge a Complaint",
              Icons.report_problem,
              Colors.redAccent,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LodgeComplaintScreen())),
            ),

            const SizedBox(height: 40),

            // --- COMPANY SECTION ---
            _buildSectionHeader("Company Portal", Colors.blueGrey),
            _buildMenuButton(
              context,
              "Find Workers (Search)",
              Icons.search,
              Colors.blueGrey,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CompanySearch())),
            ),

            const SizedBox(height: 40),

            // --- OFFICIAL SECTION ---
            _buildSectionHeader("Bureau Official Portal", Colors.teal),
            _buildMenuButton(
              context,
              "Officer Dashboard",
              Icons.admin_panel_settings,
              Colors.teal,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OfficerDashboard())),
            ),
            _buildMenuButton(
              context,
              "Manage Complaints",
              Icons.chat_bubble_outline,
              Colors.teal,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageComplaintsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build section titles
  Widget _buildSectionHeader(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
        Divider(color: color, thickness: 1.5),
        const SizedBox(height: 10),
      ],
    );
  }

  // Helper to build consistent buttons
  Widget _buildMenuButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: onPressed,
      ),
    );
  }
}
