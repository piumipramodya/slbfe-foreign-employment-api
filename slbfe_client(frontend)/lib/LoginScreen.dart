import 'package:flutter/material.dart';
import 'api_service.dart';
import 'officer_dashboard.dart'; // Standardized filename
import 'register_screen.dart';
import 'main.dart'; // CRITICAL: Required to access the HomeScreen class

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nidController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  // --- REQUIREMENT (iii/vii): LOGIN LOGIC ---
  // Demonstrates secure access control and role-based navigation [cite: 24, 38]
  void _handleLogin() async {
    setState(() => _isLoading = true);

    // Consumes the /citizens/login API endpoint [cite: 41]
    final result =
        await ApiService.login(_nidController.text, _passController.text);

    setState(() => _isLoading = false);

    if (result != null) {
      // 1. Success message to the user
      _showSnackBar("Welcome back, ${result['name']}", Colors.green);

      // 2. Navigation logic based on the 'role' returned in JSON [cite: 40]
      if (result['role'] == 'officer') {
        // Bureau Officers see the administrative dashboard [cite: 14]
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const OfficerDashboard()));
      } else {
        // Citizens are directed to the Master Hub (HomeScreen) [cite: 41]
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      // Handles failed authentication attempts
      _showSnackBar("Login failed. Check NID or Password.", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 100, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text(
                "SLBFE Portal Login",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
              const SizedBox(height: 10),
              const Text(
                "Access your foreign employment services",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // National ID Field (Matches schema requirement i) [cite: 24]
              TextField(
                controller: _nidController,
                decoration: InputDecoration(
                  labelText: "National ID",
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field (Industry good practice for security)
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child:
                          const Text("Login", style: TextStyle(fontSize: 18)),
                    ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                ),
                child: const Text(
                  "Don't have an account? Register Now",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
