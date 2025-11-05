import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Student_status extends StatefulWidget {
  const Student_status({super.key});

  @override
  State<Student_status> createState() => _Student_statusState();
}

class _Student_statusState extends State<Student_status> {
  final String baseUrl = "http://192.168.110.142:3000/api"; //ipconfig pc ของเรา
  final String currentUserId = "1";

  bool _isLoading = true;
  String _username = '';
  StatusItem? _pendingItem;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _pendingItem = null;
    });

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/user/$currentUserId')),
        http.get(Uri.parse('$baseUrl/status/$currentUserId')),
      ]).timeout(const Duration(seconds: 10));

      String fetchedUsername = 'guest';
      if (responses[0].statusCode == 200) {
        final userData = json.decode(responses[0].body);
        fetchedUsername = userData['username'] ?? 'guest';
      }

      StatusItem? fetchedStatus;
      if (responses[1].statusCode == 200) {
        final statusData = json.decode(responses[1].body);
        if (statusData != null) {
          fetchedStatus = StatusItem.fromJson(statusData);
        }
      }

      if (mounted) {
        setState(() {
          _username = fetchedUsername;
          _pendingItem = fetchedStatus;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
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
        title: _isLoading
            ? const SizedBox.shrink()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
        centerTitle: true,
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
                _buildStatusSection(item: _pendingItem),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection({StatusItem? item}) {
    Widget cardContent;

    if (item != null) {
      cardContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.date,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            item.status,
            style: TextStyle(
              color: item.status == 'Pending'
                  ? Colors.orange
                  : item.status == 'Requested Return'
                  ? Colors.purple
                  : Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else {
      cardContent = const Center(
        child: Text('No  status', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: cardContent,
          ),
        ],
      ),
    );
  }
}

class StatusItem {
  final String requestId;
  final String date;
  final String itemName;
  final String status;

  StatusItem({
    required this.requestId,
    required this.date,
    required this.itemName,
    required this.status,
  });

  factory StatusItem.fromJson(Map<String, dynamic> json) {
    String formatDate(String? dateStr) {
      if (dateStr == null) return 'N/A';
      try {
        final clean = dateStr.split('T')[0];
        return clean;
      } catch (e) {
        return 'N/A';
      }
    }

    return StatusItem(
      requestId: json['request_id'].toString(),
      date: formatDate(json['request_date']),
      itemName: json['asset_name'] ?? 'Unknown Item',
      status: json['asset_status'] ?? 'Unknown',
    );
  }
}
