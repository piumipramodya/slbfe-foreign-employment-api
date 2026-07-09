import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // CRITICAL: Matches your laptop's IPv4 address for local testing on the mobile device.
  static const String baseUrl = 'http://192.168.8.143:5000';

  // --- REQUIREMENT (iii/vii): USER AUTHENTICATION ---
  // Industry Practice: Verifies NID and Password for secure access control [cite: 38]
  static Future<Map<String, dynamic>?> login(
      String nid, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/citizens/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"nid": nid.trim(), "password": password}),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print("❌ Login Error: $e");
      return null;
    }
  }

  // --- REQUIREMENT (i): CITIZEN REGISTRATION ---
  // Any citizen can become a member through a free online registration[cite: 12].
  // Facilitates POST /citizens with details including NID, name, age, address, email, etc.[cite: 23, 24].
  static Future<bool> registerCitizen(Map<String, dynamic> data) async {
    try {
      // Industry practice: Ensure NID is trimmed before transmission[cite: 38].
      if (data.containsKey('nid')) {
        data['nid'] = data['nid'].toString().trim();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/citizens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print("📡 Registration Response: ${response.statusCode}");
      return response.statusCode == 201;
    } catch (e) {
      print("❌ Registration Error: $e");
      return false;
    }
  }

  // --- REQUIREMENT (ii): UPDATE QUALIFICATIONS & UPLOAD DOCUMENTS ---
  // Job seekers must be able to update qualifications and upload certificates[cite: 13].
  // Facilitates PUT /citizens/:nid for text skills and file paths[cite: 25, 26].
  static Future<bool> uploadDocuments({
    required String nid,
    required String newQualification,
    File? birthCert,
    File? cv,
    File? passport,
  }) async {
    try {
      final cleanNid = nid.trim();
      final url = Uri.parse('$baseUrl/citizens/$cleanNid/documents');
      var request = http.MultipartRequest('PUT', url);

      // Add text-based qualification to the request if provided
      if (newQualification.isNotEmpty) {
        request.fields['qualifications'] = newQualification;
      }

      // Helper to handle both PDF documents and JPEG images from mobile
      Future<void> attachFile(File file, String fieldName) async {
        String ext = file.path.split('.').last.toLowerCase();

        // Correctly identifies MIME type (application/pdf or image/jpeg)
        MediaType contentType = (ext == 'pdf')
            ? MediaType('application', 'pdf')
            : MediaType('image', 'jpeg');

        request.files.add(await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: contentType,
        ));
      }

      if (birthCert != null) await attachFile(birthCert, 'birthCertificate');
      if (cv != null) await attachFile(cv, 'cv');
      if (passport != null) await attachFile(passport, 'passportCopy');

      print("📡 Attempting Multi-part Upload for NID [$cleanNid]");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📡 Server Upload Response: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Document Upload Error: $e");
      return false;
    }
  }

  // --- REQUIREMENT (iii): ACCESS CITIZEN BY NATIONAL ID ---
  // Officers should be able to access any citizen’s information by their national ID[cite: 27, 28].
  static Future<Map<String, dynamic>?> getCitizenByNid(String nid) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.get(Uri.parse('$baseUrl/citizens/$cleanNid'));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print("❌ Search Error: $e");
      return null;
    }
  }

  // --- REQUIREMENT (iii): IDENTITY STATUS CHECK ---
  // Fast existence check for seeker validation workflows before uploading[cite: 27].
  static Future<Map<String, dynamic>?> checkStatus(String nid) async {
    try {
      final cleanNid = nid.trim();
      final url = Uri.parse('$baseUrl/citizens/status/$cleanNid');
      final response = await http.get(url);

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- REQUIREMENT (iii): OFFICER DASHBOARD (LIST ALL) ---
  // Bureau officers must be able to see and validate information[cite: 14].
  static Future<List> getAllCitizens() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/citizens'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- REQUIREMENT (iii): OFFICER VALIDATION ---
  // Officers should be able to verify information provided by job seekers[cite: 29, 30].
  static Future<bool> verifyCitizen(String nid) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.patch(
        Uri.parse('$baseUrl/citizens/$cleanNid/verify'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- REQUIREMENT (iv/v): COMPANY WORKER SEARCH ---
  // Foreign companies should be able to find workers based on qualifications[cite: 15, 31, 32].
  static Future<List> searchByQualification(String qual) async {
    try {
      final query = qual.trim();
      final url =
          Uri.parse('$baseUrl/citizens/find/search?qualification=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- REQUIREMENT (vi): FOREIGN LOCATION UPDATE ---
  // Citizens visit foreign companies and must update their current location[cite: 16].
  static Future<bool> updateLocation(
      String nid, double lat, double long) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.put(
        Uri.parse('$baseUrl/citizens/$cleanNid/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"lat": lat, "long": long}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- REQUIREMENT (vii): COMPLAINT MANAGEMENT ---
  // Any citizen can make a complaint and officers see content and reply[cite: 17].
  static Future<bool> lodgeComplaint(String nid, String message) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.post(
        Uri.parse('$baseUrl/citizens/$cleanNid/complaint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": message}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> replyToComplaint(
      String nid, String complaintId, String reply) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.patch(
        Uri.parse('$baseUrl/citizens/$cleanNid/complaint/$complaintId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"reply": reply}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- REQUIREMENT (vii) EXTENSION: VIEW REPLIES ---
  // Fetches the list of complaints and replies for a specific citizen.
  // Demonstrates advanced data retrieval for the final report[cite: 40, 46].
  static Future<List> getCitizenComplaints(String nid) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.get(Uri.parse('$baseUrl/citizens/$cleanNid'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['complaints'] ?? [];
      }
      return [];
    } catch (e) {
      print("❌ Error fetching complaints: $e");
      return [];
    }
  }

  // --- REQUIREMENT (viii): CONTACT INFORMATION RETRIEVAL ---
  // SLBFE staff can collect information about contacts of any citizen[cite: 35, 36].
  static Future<Map<String, dynamic>?> getCitizenContacts(String nid) async {
    try {
      final cleanNid = nid.trim();
      final response =
          await http.get(Uri.parse('$baseUrl/citizens/$cleanNid/contacts'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- REQUIREMENT (vii): DEACTIVATE ACCOUNT ---
  // Staff can deactivate an individual’s account if the citizen is deceased[cite: 33, 34].
  // Facilitates DELETE /citizens/:nid using a soft-delete status update.
  static Future<bool> deactivateCitizen(String nid) async {
    try {
      final cleanNid = nid.trim();
      final response = await http.delete(
        Uri.parse('$baseUrl/citizens/$cleanNid'),
      );

      print("📡 Deactivation API Status: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Deactivation Error: $e");
      return false;
    }
  }
}
