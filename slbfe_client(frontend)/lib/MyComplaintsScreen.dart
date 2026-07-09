import 'package:flutter/material.dart';
import 'api_service.dart';

class MyComplaintsScreen extends StatefulWidget {
  final String nid;
  const MyComplaintsScreen({super.key, required this.nid});

  @override
  _MyComplaintsScreenState createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  List _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  void _fetchComplaints() async {
    final data = await ApiService.getCitizenComplaints(widget.nid);
    setState(() {
      _complaints = data.reversed.toList(); // Show newest first
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Complaints & Replies"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? const Center(child: Text("No complaints found for this NID."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final c = _complaints[index];
                    final String reply = c['reply'] ?? "";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Issue: ${c['message']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            const Divider(),
                            const Text("OFFICER REPLY:",
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            const SizedBox(height: 5),
                            Text(
                              reply.isEmpty
                                  ? "Pending review by SLBFE officers..."
                                  : reply,
                              style: TextStyle(
                                fontStyle: reply.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: reply.isEmpty
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
