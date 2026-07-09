import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // REQUIRED: Add to pubspec.yaml
import 'api_service.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  _OfficerDashboardState createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  // --- STATE VARIABLES ---
  List _citizens = [];
  bool _isFetching = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); // Requirement (iii): Load for initial review
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- REQUIREMENT (iii): Load All Citizens ---
  void _loadData() async {
    setState(() => _isFetching = true);
    final data = await ApiService.getAllCitizens();
    setState(() {
      _citizens = data;
      _isFetching = false;
    });
  }

  // --- REQUIREMENT (iii): Search by National ID ---
  // Direct record access via GET /citizens/:nid
  void _onSearch() async {
    String nid = _searchController.text.trim();
    if (nid.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isFetching = true);
    final result = await ApiService.getCitizenByNid(nid);
    setState(() => _isFetching = false);

    if (result != null) {
      _showCitizenDetails(result); // Triggers full profile view
    } else {
      _showSnackBar("No citizen found with NID: $nid", Colors.orange);
    }
  }

  // --- REQUIREMENT (viii): Collect Information about Contacts ---
  // Dedicated popup for GET /citizens/:nid/contacts
  void _showQuickContacts(String nid, String name) async {
    setState(() => _isFetching = true);
    final contact = await ApiService.getCitizenContacts(nid);
    setState(() => _isFetching = false);

    if (contact != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Emergency Contacts: $name",
              style: const TextStyle(
                  color: Colors.purple, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Contact Name", contact['contactName']),
              _detailRow("Phone Number", contact['contactPhone']),
              _detailRow("Relationship", contact['relationship']),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
          ],
        ),
      );
    }
  }

  // --- HELPER: Open File in Browser ---
  Future<void> _openFile(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      _showSnackBar("Document file not found on server", Colors.red);
      return;
    }

    final cleanPath = relativePath.replaceAll('\\', '/');
    final String fullUrl = "${ApiService.baseUrl}/$cleanPath";
    final Uri url = Uri.parse(fullUrl);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Could not launch document viewer", Colors.red);
    }
  }

  // --- REQUIREMENT (iii): Official Verification ---
  void _verify(String nid) async {
    bool success = await ApiService.verifyCitizen(nid);
    if (success) {
      _showSnackBar("Citizen Profile Verified Successfully!", Colors.green);
      _loadData();
    } else {
      _showSnackBar("Verification failed", Colors.red);
    }
  }

  // --- REQUIREMENT (vii): Deactivate Account ---
  void _handleDeactivation(String nid, String name) async {
    bool confirm = await _showConfirmDialog(name);
    if (confirm) {
      bool success = await ApiService.deactivateCitizen(nid);
      if (success) {
        Navigator.pop(context); // Close detail popup
        _loadData();
        _showSnackBar("Account for $name deactivated", Colors.black);
      }
    }
  }

  // --- COMPREHENSIVE PROFILE VIEW ---
  // Requirement (i) & (iii): Displays ALL registration details for validation
  void _showCitizenDetails(Map citizen) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${citizen['name'] ?? 'Citizen'} - Profile",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.teal)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Registration Details (Requirement i)
              _detailRow("NID", citizen['nid']),
              _detailRow(
                  "Age", citizen['age']?.toString()), // Added for Compliance
              _detailRow("Address", citizen['address']), // Added for Compliance
              _detailRow("Profession", citizen['profession']),
              _detailRow("Affiliation", citizen['affiliation']),
              _detailRow("Email", citizen['email']),

              const Divider(),
              const Text("QUALIFICATIONS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.indigo)),
              const SizedBox(height: 5),
              Text(
                  citizen['qualifications']?.join(", ") ??
                      "No qualifications added",
                  style: const TextStyle(fontSize: 14)),

              const Divider(),
              const Text("DOCUMENT EVIDENCE",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.indigo)),
              const SizedBox(height: 5),
              _buildFileRow("Birth Certificate", citizen['birthCertificate']),
              _buildFileRow("CV / Resume", citizen['cv']),
              _buildFileRow("Passport Copy", citizen['passportCopy']),

              const Divider(),
              const Text("EMERGENCY CONTACT",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                  "Name: ${citizen['emergencyContact']?['contactName'] ?? 'N/A'}"),
              Text(
                  "Phone: ${citizen['emergencyContact']?['contactPhone'] ?? 'N/A'}"),

              const Divider(),
              const Text("ADMIN ACTIONS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _handleDeactivation(
                    citizen['nid'], citizen['name'] ?? "Citizen"),
                icon: const Icon(Icons.person_off),
                label: const Text("Deactivate (Deceased)"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Future<bool> _showConfirmDialog(String name) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Deactivation"),
            content: Text(
                "Are you sure you want to deactivate $name's account? This is for deceased citizens only."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Confirm",
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bureau Officer Dashboard"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          // REQUIREMENT (iii): Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by National ID",
                prefixIcon: const Icon(Icons.badge),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.teal),
                  onPressed: _onSearch,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),

          Expanded(
            child: _isFetching
                ? const Center(child: CircularProgressIndicator())
                : _citizens.isEmpty
                    ? const Center(child: Text("No citizens found."))
                    : ListView.builder(
                        itemCount: _citizens.length,
                        itemBuilder: (context, index) {
                          final citizen = _citizens[index];
                          bool isVerified = citizen['isVerified'] ?? false;
                          bool isDeactivated =
                              citizen['status'] == 'deactivated';

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            color: isDeactivated
                                ? Colors.grey.shade200
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDeactivated
                                    ? Colors.grey
                                    : (isVerified
                                        ? Colors.green
                                        : Colors.orange),
                                child: Icon(
                                    isDeactivated
                                        ? Icons.block
                                        : (isVerified
                                            ? Icons.check
                                            : Icons.priority_high),
                                    color: Colors.white),
                              ),
                              title: Text(citizen['name'] ?? "Unknown",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: isDeactivated
                                          ? TextDecoration.lineThrough
                                          : null)),
                              subtitle: Text(
                                  "NID: ${citizen['nid']} \nStatus: ${isDeactivated ? 'DEACTIVATED' : (isVerified ? 'Verified' : 'Pending')}"),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _showCitizenDetails(citizen),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.contact_phone,
                                        color: Colors.purple),
                                    onPressed: () => _showQuickContacts(
                                        citizen['nid'],
                                        citizen['name'] ?? "Citizen"),
                                  ),
                                  if (!isVerified && !isDeactivated)
                                    ElevatedButton(
                                      onPressed: () => _verify(citizen['nid']),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white),
                                      child: const Text("Verify"),
                                    )
                                  else if (isVerified && !isDeactivated)
                                    const Icon(Icons.verified_user,
                                        color: Colors.green, size: 28),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text("$label: ${value ?? 'Not Provided'}",
            style: const TextStyle(fontSize: 14)),
      );

  Widget _buildFileRow(String label, String? path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          path != null && path.isNotEmpty
              ? TextButton.icon(
                  onPressed: () => _openFile(path),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text("View"),
                )
              : const Text("Missing",
                  style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
