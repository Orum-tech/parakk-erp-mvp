import 'package:flutter/material.dart';

class IncidentLogScreen extends StatefulWidget {
  const IncidentLogScreen({super.key});

  @override
  State<IncidentLogScreen> createState() => _IncidentLogScreenState();
}

class _IncidentLogScreenState extends State<IncidentLogScreen> {
  // Mock Data
  final List<Map<String, String>> _incidents = [
    {
      "student": "Vikram Singh",
      "issue": "Fighting in class",
      "severity": "Severe",
      "date": "24 Oct 2023",
      "status": "Resolved",
      "description": "Engaged in physical altercation with another student during break time."
    },
    {
      "student": "Rohan Das",
      "issue": "Late submission",
      "severity": "Minor",
      "date": "22 Oct 2023",
      "status": "Pending",
      "description": "Failed to submit Maths assignment on time despite multiple reminders."
    },
    {
      "student": "Aryan Sharma",
      "issue": "Disturbing class",
      "severity": "Moderate",
      "date": "20 Oct 2023",
      "status": "Action Taken",
      "description": "Repeatedly interrupting the lecture and creating noise."
    },
    {
      "student": "Sneha Gupta",
      "issue": "Usage of Mobile Phone",
      "severity": "Severe",
      "date": "18 Oct 2023",
      "status": "Under Review",
      "description": "Found using mobile phone in library which is strictly prohibited."
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredIncidents = _incidents.where((incident) {
      final name = incident['student']!.toLowerCase();
      final issue = incident['issue']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || issue.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Disciplinary Log",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded, color: Colors.black54),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search student or issue...",
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // 2. Incident List
          Expanded(
            child: filteredIncidents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredIncidents.length,
                    itemBuilder: (context, index) {
                      return _buildIncidentCard(filteredIncidents[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Opening report form... 📝")),
          );
        },
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text(
          "Report Incident",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "No incidents found",
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, String> incident) {
    Color severityColor;
    switch (incident['severity']) {
      case "Severe":
        severityColor = Colors.red;
        break;
      case "Moderate":
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Severity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 18, color: severityColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      incident['student']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    incident['severity']!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: Issue & Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident['issue']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident['description']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 15),
                
                // Footer: Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          incident['date']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Status: ${incident['status']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}