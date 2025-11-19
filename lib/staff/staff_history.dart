import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:flutter_application_1/staff/request.dart';
import 'package:flutter_application_1/staff/staff.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class StaffHistory extends StatefulWidget {
  const StaffHistory({super.key});

  @override
  State<StaffHistory> createState() => _StaffHistoryState();
}

class _StaffHistoryState extends State<StaffHistory> {
  final String baseUrl = "http://192.168.234.1:3000/api";
  int? staffId;
  String? username;
  bool _isLoading = true;
  int _selectedIndex = 2;
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    // ========== ดึง user_id จาก token ==========
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');

    final jwt = JWT.decode(token!);
    Map playload = jwt.payload;

    staffId = playload['user_id'] as int;

    if (staffId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login again.")));
      setState(() => _isLoading = false);
      return;
    }
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (staffId == null) return;
    setState(() {
      _isLoading = true;
      _historyItems = [];
    });

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/staff/history'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _historyItems = data
              .map((jsonItem) => HistoryItem.fromJson(jsonItem))
              .toList()
              .reversed
              .toList(); // ทำให้ล่าสุดอยู่บน
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load history: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching history: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error while loading history")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Request()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Staff()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = 16.0;
    final minCardHeight =
        screenHeight - appBarHeight - topPadding - bottomPadding;

    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minCardHeight),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24.0),
                          _buildHistorySection(items: _historyItems),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHistorySection({required List<HistoryItem> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12.0),
          if (items.isEmpty)
            const Center(
              child: Text(
                'No history found.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(item: items[index]);
              },
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12.0),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({required HistoryItem item}) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'Pending':
          return Colors.orange;
        case 'Rejected':
        case 'Disable':
          return Colors.red;
        case 'Request Return':
          return Colors.purple;
        case 'Borrowed':
          return Colors.blue;
        case 'Returned':
          return Colors.deepPurpleAccent;
        default:
          return Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ID #${item.requestId}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.item,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.dateRange,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  item.status,
                  style: TextStyle(
                    color: getStatusColor(item.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Borrower',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                item.borrower,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              Text(
                'Lender',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                item.lender,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Returned',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

              Text(
                item.staff,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.lightBlue[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.refresh, "Return"),
          _buildNavItem(1, Icons.home, "Staff"),
          _buildNavItem(2, Icons.history, "History"),
          _buildNavItem(3, Icons.logout, "Logout"),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool largeIcon = false,
  }) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: largeIcon ? 42 : 28,
            color: isSelected ? Colors.purple : Colors.black,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.purple : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryItem {
  final String item;
  final String dateRange;
  final String borrower;
  final String staff;
  final String lender;
  final String status;
  final String requestId;

  HistoryItem({
    required this.item,
    required this.dateRange,
    required this.borrower,
    required this.staff,
    required this.lender,
    required this.status,
    required this.requestId,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    String formatDate(String? dateStr) {
      if (dateStr == null) return 'N/A';
      try {
        final DateTime utcDateTime = DateTime.parse(dateStr);
        final DateTime localDateTime = utcDateTime.toLocal();
        return localDateTime.toString().split(' ')[0];
      } catch (e) {
        return dateStr.split('T')[0];
      }
    }

    final String dateRange =
        "${formatDate(json['borrow_date'])} To ${formatDate(json['return_date'])}";

    final String requestStatus = json['request_status'] ?? 'Unknown';
    final String returnStatus = json['return_status'];

    String finalStatus;
    String returnedBy = json['staff_name'] ?? '-';

    if (returnStatus == 'Returned') {
      finalStatus = 'Returned';
    } else if (requestStatus == 'Approved' && returnStatus == 'Not Returned') {
      finalStatus = 'Borrowed';
    } else if (requestStatus == 'Approved' &&
        returnStatus == 'Requested Return') {
      finalStatus = 'Request Return';
    } else if (requestStatus == 'Rejected') {
      finalStatus = 'Rejected';
    } else {
      finalStatus = requestStatus;
    }

    final String requestId = (json['request_id'] ?? '').toString();

    return HistoryItem(
      item: json['asset_name'] ?? 'Unknown Item',
      dateRange: dateRange,
      borrower: json['borrower_name'] ?? '-',
      staff: returnedBy,
      lender: json['lender_name'] ?? '-',
      status: finalStatus,
      requestId: requestId.isEmpty ? '-' : requestId,
    );
  }
}
