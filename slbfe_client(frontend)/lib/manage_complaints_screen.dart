import 'package:flutter/material.dart';
import 'api_service.dart';

class ManageComplaintsScreen extends StatefulWidget {
  const ManageComplaintsScreen({super.key});

  @override
  _ManageComplaintsScreenState createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> {
  List _citizensWithComplaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  // Fetches all citizens and filters those who have at least one complaint
  void _loadComplaints() async {
    setState(() => _isLoading = true);
    final all = await ApiService.getAllCitizens();

    setState(() {
      _citizensWithComplaints = all
          .where((c) =>
              c['complaints'] != null && (c['complaints'] as List).isNotEmpty)
          .toList();
      _isLoading = false;
    });
  }

  // Sends the officer's reply to the backend
  void _sendReply(String nid, String complaintId, String replyText) async {
    if (replyText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reply message")),
      );
      return;
    }

    bool success =
        await ApiService.replyToComplaint(nid, complaintId, replyText);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Reply sent successfully!"),
            backgroundColor: Colors.green),
      );
      _loadComplaints(); // Refresh the list to show the new reply
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to send reply"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bureau - Manage Complaints"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _citizensWithComplaints.isEmpty
              ? const Center(child: Text("No active complaints found."))
              : RefreshIndicator(
                  onRefresh: () async => _loadComplaints(),
                  child: ListView.builder(
                    itemCount: _citizensWithComplaints.length,
                    itemBuilder: (context, index) {
                      final citizen = _citizensWithComplaints[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        elevation: 4,
                        child: ExpansionTile(
                          leading: const Icon(Icons.person, color: Colors.teal),
                          title: Text(citizen['name'] ?? "Unknown Citizen"),
                          subtitle: Text("NID: ${citizen['nid']}"),
                          children: (citizen['complaints'] as List).map((comp) {
                            final replyController =
                                TextEditingController(text: comp['reply']);

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  Text(
                                    "Complaint Date: ${comp['date'].toString().substring(0, 10)}",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Issue: ${comp['message']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 15),
                                  TextField(
                                    controller: replyController,
                                    decoration: const InputDecoration(
                                      labelText: "Officer Official Reply",
                                      border: OutlineInputBorder(),
                                      hintText: "Enter response here...",
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _sendReply(
                                          citizen['nid'],
                                          comp['_id'],
                                          replyController.text),
                                      icon: const Icon(Icons.send),
                                      label: const Text("Send Reply"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
