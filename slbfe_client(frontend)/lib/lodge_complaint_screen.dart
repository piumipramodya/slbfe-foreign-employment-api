import 'package:flutter/material.dart';
import 'api_service.dart';
import 'MyComplaintsScreen.dart'; // Ensure this file is created

class LodgeComplaintScreen extends StatefulWidget {
  const LodgeComplaintScreen({super.key});

  @override
  _LodgeComplaintScreenState createState() => _LodgeComplaintScreenState();
}

class _LodgeComplaintScreenState extends State<LodgeComplaintScreen> {
  final _nidController = TextEditingController();
  final _messageController = TextEditingController();

  // State variables for the Verify-First logic
  bool _isFound = false;
  bool _isVerified = false;
  String _citizenName = "";
  bool _isLoading = false;

  @override
  void dispose() {
    _nidController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- REQUIREMENT (iii/vii): Identity Verification ---
  void _checkIdentity() async {
    final String nid = _nidController.text.trim();
    if (nid.isEmpty) {
      _showSnackBar("Please enter your NID", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final data = await ApiService.checkStatus(nid);

    setState(() {
      _isLoading = false;
      if (data != null) {
        _isFound = true;
        _citizenName = data['name'];
        _isVerified = data['isVerified'];
      } else {
        _isFound = false;
        _showSnackBar("NID not registered! Please register first.", Colors.red);
      }
    });
  }

  // --- REQUIREMENT (vii): Submit Complaint ---
  void _submit() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar("Please describe your complaint", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    bool success = await ApiService.lodgeComplaint(
        _nidController.text.trim(), _messageController.text);

    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar("Complaint Lodged Successfully!", Colors.green);
      // Success delay for UX
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showSnackBar("Failed to lodge complaint.", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lodge a Complaint"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Identify Yourself",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nidController,
              decoration: const InputDecoration(
                labelText: "Confirm Your NID",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 15),

            // --- Verification & History Actions ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkIdentity,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white),
                    child: const Text("Verify Identity"),
                  ),
                ),
                const SizedBox(width: 10),
                // NEW: Requirement (vii) - Check existing replies
                ElevatedButton.icon(
                  onPressed: () {
                    final String nid = _nidController.text.trim();
                    if (nid.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyComplaintsScreen(nid: nid)),
                      );
                    } else {
                      _showSnackBar("Enter NID to view history", Colors.orange);
                    }
                  },
                  icon: const Icon(Icons.history),
                  label: const Text("Status"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white),
                ),
              ],
            ),

            // --- Section revealed only if NID is found ---
            if (_isFound) ...[
              const Divider(height: 50, thickness: 2),
              Text(
                "Welcome, $_citizenName",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
              const SizedBox(height: 10),

              // Status Indicator
              Row(
                children: [
                  Icon(
                    _isVerified ? Icons.verified : Icons.pending,
                    color: _isVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isVerified ? "Verified Citizen" : "Pending Verification",
                    style: TextStyle(
                        color: _isVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              const Text("Describe your issue:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Enter details of your complaint...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: const Text("Submit Official Complaint"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
