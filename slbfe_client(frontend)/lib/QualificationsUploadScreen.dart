import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';

class QualificationsUploadScreen extends StatefulWidget {
  const QualificationsUploadScreen({super.key});

  @override
  _QualificationsUploadScreenState createState() =>
      _QualificationsUploadScreenState();
}

class _QualificationsUploadScreenState
    extends State<QualificationsUploadScreen> {
  // Controllers
  final _nidController = TextEditingController();
  final _qualController = TextEditingController();

  // File State
  File? _birthCert;
  File? _cv;
  File? _passport;
  bool _isLoading = false;

  @override
  void dispose() {
    _nidController.dispose();
    _qualController.dispose();
    super.dispose();
  }

  // --- LOGIC: File Picking ---
  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        if (type == 'birth') _birthCert = File(result.files.single.path!);
        if (type == 'cv') _cv = File(result.files.single.path!);
        if (type == 'passport') _passport = File(result.files.single.path!);
      });
    }
  }

  // --- LOGIC A: Only update the text qualification ---
  void _updateTextOnly() async {
    final String nid = _nidController.text.trim();
    final String qual = _qualController.text.trim();

    if (nid.isEmpty || qual.isEmpty) {
      _showSnackBar("Please enter NID and Qualification text", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    bool success = await ApiService.uploadDocuments(
      nid: nid,
      newQualification: qual,
      birthCert: null,
      cv: null,
      passport: null,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar("Qualifications Updated Successfully!", Colors.green);
      _qualController.clear();
    } else {
      _showSnackBar(
          "Update Failed. Check NID or Server Connection.", Colors.red);
    }
  }

  // --- LOGIC B: Only update documents ---
  void _uploadFilesOnly() async {
    final String nid = _nidController.text.trim();

    if (nid.isEmpty) {
      _showSnackBar("Please enter your National ID first", Colors.orange);
      return;
    }

    if (_birthCert == null && _cv == null && _passport == null) {
      _showSnackBar(
          "Please select at least one document to upload", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    bool success = await ApiService.uploadDocuments(
      nid: nid,
      newQualification: "",
      birthCert: _birthCert,
      cv: _cv,
      passport: _passport,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar("Documents Uploaded Successfully!", Colors.green);
      setState(() {
        _birthCert = null;
        _cv = null;
        _passport = null;
      });
    } else {
      _showSnackBar(
          "Upload Failed. Check NID or Server Connection.", Colors.red);
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
        title: const Text("Job Seeker Portal"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STEP 1: Identification
            _buildSectionHeader(
                "Step 1: Identify Yourself", Icons.badge), // Changed ; to ,
            _buildTextField(
                _nidController, "National ID", Icons.numbers), // Changed ; to ,

            const SizedBox(height: 30),

            // SECTION 1: Text Qualifications
            _buildSectionHeader(
                "Step 2: Update Skills", Icons.school), // Changed ; to ,
            _buildTextField(_qualController,
                "New Qualification (e.g. NVQ Level 4)", Icons.edit_note,
                maxLines: 2), // Changed ; to ,
            const SizedBox(height: 15),
            _isLoading
                ? const Center(child: LinearProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _updateTextOnly,
                    icon: const Icon(Icons.update),
                    label: const Text("Update Qualifications Only"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white),
                  ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(thickness: 1.5),
            ),

            // SECTION 2: Document Uploads
            _buildSectionHeader(
                "Step 3: Upload Certificates", Icons.cloud_upload),
            _buildFileTile(
                "Birth Certificate", _birthCert, () => _pickFile('birth')),
            _buildFileTile("Current CV (Resume)", _cv, () => _pickFile('cv')),
            _buildFileTile(
                "Passport Copy", _passport, () => _pickFile('passport')),

            const SizedBox(height: 20),

            _isLoading
                ? const SizedBox.shrink()
                : ElevatedButton.icon(
                    onPressed: _uploadFilesOnly,
                    icon: const Icon(Icons.file_upload),
                    label: const Text("Upload Documents Only"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }

  // Helper UI for Section Titles
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  // Helper UI for Text Fields
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Helper UI for File Picking Tiles
  Widget _buildFileTile(String title, File? file, VoidCallback onPick) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
          file == null ? "No file selected" : file.path.split('/').last,
          style: TextStyle(color: file == null ? Colors.grey : Colors.green)),
      trailing: IconButton(
        icon: Icon(file == null ? Icons.upload_file : Icons.check_circle,
            color: file == null ? Colors.indigo : Colors.green),
        onPressed: onPick,
      ),
    );
  }
}
