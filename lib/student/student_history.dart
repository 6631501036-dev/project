import 'package:flutter/material.dart';

class Student_history extends StatelessWidget {
  const Student_history({super.key});

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

      body: SingleChildScrollView(
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
                _buildProfileSection(),
                const SizedBox(height: 24.0),
                _buildStatusSection(),
                const SizedBox(height: 16.0),
                //line
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Divider(color: Color(0xFFEEEEEE)),
                ),
                const SizedBox(height: 16.0),
                _buildHistorySection(),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          child: const Text(
            'S',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        const Text(
          'S  A  R  A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 6.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
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
          _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
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
          _buildHistoryCard(
            item: 'Football',
            dateRange: '10/15/2025 - 10/17/2025',
            details: _buildHistoryDetails(),
          ),
          const SizedBox(height: 12.0),
          _buildHistoryCard(
            item: 'Volleyball',
            dateRange: '10/10/2025 - 10/10/2025',
            details: _buildHistoryDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
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
                '10/18/2025',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Basketball',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Text(
            'Pending',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required String item,
    required String dateRange,
    Widget? details,
  }) {
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
                item,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateRange,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (details != null) details,
        ],
      ),
    );
  }

  Widget _buildHistoryDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lender', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const Text(
          'lender.Doe',
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'returned',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const Text(
          'staff.Doe',
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
      ],
    );
  }
}
