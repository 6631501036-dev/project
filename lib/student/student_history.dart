import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRecord {
  final String id, item, borrowDate, returnDate, lender, staff, status;
  const HistoryRecord({
    required this.id,
    required this.item,
    required this.borrowDate,
    required this.returnDate,
    required this.lender,
    required this.staff,
    required this.status,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
    id: json['request_id'].toString(),
    item: json['asset_name'] ?? '-',
    borrowDate: json['borrow_date']?.toString().split('T').first ?? '-',
    returnDate: json['return_date']?.toString().split('T').first ?? '-',
    lender: json['lender_name'] ?? '-',
    staff: json['staff_name'] ?? '-',
    status: json['approval_status'] ?? '-',
  );
}

class StudentHistory extends StatefulWidget {
  const StudentHistory({super.key});
  @override
  State<StudentHistory> createState() => _StudentHistoryState();
}

class _StudentHistoryState extends State<StudentHistory> {
  final String baseUrl = "http://192.168.234.1:3000";
  int? borrowerId;
  String? username;
  bool _loading = true;
  List<HistoryRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final data = json.decode(token);
    borrowerId = data['user_id'];
    username = data['username'];
    await _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (borrowerId == null) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/borrower/history/$borrowerId"),
      );
      final body = json.decode(res.body);
      if (body['success']) {
        _records = List<HistoryRecord>.from(
          body['history'].map((x) => HistoryRecord.fromJson(x)),
        );
      }
    } catch (e) {
      print("Fetch history error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: Text(username ?? "History"),
        backgroundColor: Colors.blue[200],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(child: Text("No history found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, i) {
                final r = _records[i];
                return Card(
                  child: ListTile(
                    title: Text(r.item),
                    subtitle: Text(
                      "Borrowed: ${r.borrowDate} → ${r.returnDate}\nStatus: ${r.status}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
