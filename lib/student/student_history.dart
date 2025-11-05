import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

class Student_history extends StatefulWidget {
  const Student_history({super.key});

  @override
  State<Student_history> createState() => _Student_historyState();
}

class _Student_historyState extends State<Student_history> {

  final String baseUrl = "http://192.168.110.142:3000/api"; //ipconfig pc ของเรา
  final String currentUserId = "1";
 

  bool _isLoading = true;
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }


  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _historyItems = [];
    });

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/history/$currentUserId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
      
        final List<dynamic> data = json.decode(response.body);

      
        setState(() {
          _historyItems = data
              .map((jsonItem) => HistoryItem.fromJson(jsonItem))
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching history: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = 16.0;
    final minCardHeight =
        screenHeight - appBarHeight - topPadding - bottomPadding;

    return SingleChildScrollView(
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
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12.0);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({required HistoryItem item}) {
    // ฟังก์ชันช่วยเลือกสีให้ตรงกับ DB
    Color getStatusColor(String status) {
      if (status == 'Approved') {
        return Colors.green;
      } else if (status == 'Rejected' || status == 'Cancelled') {
        return Colors.red;
      }
      return Colors.grey;
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          _buildHistoryDetails(item: item),
        ],
      ),
    );
  }

  Widget _buildHistoryDetails({required HistoryItem item}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lender', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(
          item.lender, 
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'returned',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Text(
          item.returnedBy, 
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }
}


class HistoryItem {
  final String item;
  final String dateRange;
  final String lender;
  final String returnedBy;
  final String status;

  HistoryItem({
    required this.item,
    required this.dateRange,
    required this.lender,
    required this.returnedBy,
    required this.status,
  });


  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    // ฟังก์ชันช่วย Format วันที่
    String formatDate(String? dateStr) {
      if (dateStr == null) return 'N/A';
      try {
        final utc = DateTime.parse(dateStr).toUtc();
        final local = utc.toLocal();
        return local.toString().split(' ')[0]; 
      } catch (e) {
        return 'N/A';
      }
    }

   
   
    final String dateRange =
        "${formatDate(json['borrow_date'])} - ${formatDate(json['return_date'])}";

    return HistoryItem(
      item: json['asset_name'] ?? 'Unknown Item',
      dateRange: dateRange,
      lender: json['lender_name'] ?? 'N/A', 
      returnedBy: json['staff_name'] ?? 'N/A', 
      status: json['request_status'] ?? 'Unknown', 
    );
  }
}
