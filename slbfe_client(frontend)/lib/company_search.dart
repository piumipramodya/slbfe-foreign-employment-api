import 'package:flutter/material.dart';
import 'api_service.dart';

class CompanySearch extends StatefulWidget {
  const CompanySearch({super.key});

  @override
  _CompanySearchState createState() => _CompanySearchState();
}

class _CompanySearchState extends State<CompanySearch> {
  final _searchController = TextEditingController();
  List _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Calls the backend: /citizens/find/search?qualification=...
      final data = await ApiService.searchByQualification(query);
      setState(() {
        _results = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Search failed. Check your connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Portal - Find Workers"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Input Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey.withOpacity(0.1),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by Qualification (e.g., Engineering)",
                hintText: "Enter skill or degree...",
                prefixIcon: const Icon(Icons.school),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blueGrey),
                  onPressed: _onSearch,
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),

          // Results Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty && _hasSearched
                    ? _buildEmptyState()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final worker = _results[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              worker['name'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Profession: ${worker['profession']}"),
                Text("NID: ${worker['nid']}"),
              ],
            ),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: Colors.blue),
                Text("Verified",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No verified workers found with this qualification.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
