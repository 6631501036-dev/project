import 'package:flutter/material.dart';
import 'student_history.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  final List<Map<String, dynamic>> equipmentList = [
    {
      'name': 'Football',
      'status': 'Available',
      'image': 'asset/image/football ball.png',
    },
    {
      'name': 'Basketball',
      'status': 'Borrowed',
      'image': 'asset/image/basketball.png',
    },
    {
      'name': 'Volleyball',
      'status': 'Pending',
      'image': 'asset/image/volleyball.png',
    },
    {
      'name': 'Badminton Shuttle',
      'status': 'Disable',
      'image': 'asset/image/shuttlecock.png',
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Borrowed':
        return Colors.teal;
      case 'Pending':
        return Colors.orange;
      case 'Disable':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  bool isBorrowEnabled(String status) => status == 'Available';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        title: const Text(
          'Sport Equipment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded), // Replace with custom icon if needed
            onPressed: () {
              // Logout logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Student_history()),
                    );
                  },
                  label: const Text('History'),
                  icon: const Icon(Icons.history_edu_rounded, color: Colors.black),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: equipmentList.map((item) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(item['status'],
                                    style: TextStyle(
                                        color: getStatusColor(item['status']),
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: isBorrowEnabled(item['status'])
                                      ? () {
                                          // Navigate to detail page
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isBorrowEnabled(item['status'])
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Borrow'),
                                ),
                              ],
                            ),
                          ),
                          Image.asset(item['image'], width: 80),
                        ],
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}