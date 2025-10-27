import 'package:flutter/material.dart';
import 'dart:async';

class Student_history extends StatefulWidget {
  const Student_history({super.key});

  @override
  State<Student_history> createState() => _Student_historyState();
}

class _Student_historyState extends State<Student_history> {
  bool _isLoading = true;

  String _studentName = '';
  String _avatarLetter = '';
  StatusItem? _pendingItem;
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  Future<void> _fetchData() async {
    // API

    // จำลองการหน่วงเวลาของ API
    await Future.delayed(const Duration(seconds: 1));

    final studentName = 'S  A  R  A';
    final avatarLetter = 'S';
    final pendingItem = StatusItem(
      date: '10/18/2025',
      itemName: 'Basketball',
      status: 'Pending',
    );
    final historyItems = [
      HistoryItem(
        item: 'Football',
        dateRange: '10/15/2025 - 10/17/2025',
        lender: 'lender.Doe',
        returnedBy: 'staff.Doe',
      ),
      HistoryItem(
        item: 'Volleyball',
        dateRange: '10/10/2025 - 10/10/2025',
        lender: 'lender.Doe',
        returnedBy: 'staff.Doe',
      ),
    ];

    if (mounted) {
      // (เช็คว่า widget ยังอยู่)
      setState(() {
        _studentName = studentName;
        _avatarLetter = avatarLetter;
        _pendingItem = pendingItem;
        _historyItems = historyItems;
        _isLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
      // ตรวจสอบสถานะ Loading ก่อนแสดงผล
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24.0),

              _buildProfileSection(
                name: _studentName,
                avatarLetter: _avatarLetter,
              ),
              const SizedBox(height: 24.0),
              _buildStatusSection(item: _pendingItem),
              const SizedBox(height: 16.0),
              //line
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Divider(color: Color(0xFFEEEEEE)),
              ),
              const SizedBox(height: 16.0),
              _buildHistorySection(items: _historyItems),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  //  ปรับแก้รับพารามิเตอร์ name และ avatarLetter
  Widget _buildProfileSection({
    required String name,
    required String avatarLetter,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          child: Text(
            avatarLetter,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 6.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection({StatusItem? item}) {
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

          if (item != null)
            _buildStatusCard(item: item) // ถ้ามี ก็สร้างการ์ด
          else
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Center(
                child: Text(
                  'No pending items.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required StatusItem item}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
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
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection({required List<HistoryItem> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

class StatusItem {
  final String date;
  final String itemName;
  final String status;

  StatusItem({
    required this.date,
    required this.itemName,
    required this.status,
  });
}

class HistoryItem {
  final String item;
  final String dateRange;
  final String lender;
  final String returnedBy;

  HistoryItem({
    required this.item,
    required this.dateRange,
    required this.lender,
    required this.returnedBy,
  });
}
