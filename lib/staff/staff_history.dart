import 'package:flutter/material.dart';
import 'package:flutter_application_1/staff/menu_staff.dart';
import 'package:flutter_application_1/staff/request.dart';
import 'package:flutter_application_1/staff/staff.dart';
import 'package:flutter_application_1/login/login.dart';

class StaffHistory extends StatefulWidget {
  final int staffId;
  final String username;

  const StaffHistory({
    super.key,
    required this.staffId,
    required this.username,
  });

  @override
  State<StaffHistory> createState() => _StaffHistoryState();
}

class _StaffHistoryState extends State<StaffHistory> {
  int _selectedIndex = 3;
  int _hoverIndex = -1;

  final List<Map<String, String>> _records = [
    {
      "id": "1",
      "item": "Football",
      "borrow": "10/11/2025",
      "return": "12/11/2025",
      "student": "student_1",
      "lender": "lender_1",
      "staff": "staff_1",
      "status": "Approved",
    },
    {
      "id": "2",
      "item": "Basketball",
      "borrow": "11/11/2025",
      "return": "13/11/2025",
      "student": "student_2",
      "lender": "lender_2",
      "staff": "-",
      "status": "Disapproved",
    },
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MenuStaff(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Request(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Staff(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
        break;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Disapproved":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Borrow History (${widget.username})",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("Item")),
                    DataColumn(label: Text("Borrow Date")),
                    DataColumn(label: Text("Return Date")),
                    DataColumn(label: Text("Student")),
                    DataColumn(label: Text("Lender")),
                    DataColumn(label: Text("Staff")),
                    DataColumn(label: Text("Status")),
                  ],
                  rows: _records
                      .map(
                        (r) => DataRow(
                          cells: [
                            DataCell(Text(r["id"]!)),
                            DataCell(Text(r["item"]!)),
                            DataCell(Text(r["borrow"]!)),
                            DataCell(Text(r["return"]!)),
                            DataCell(Text(r["student"]!)),
                            DataCell(Text(r["lender"]!)),
                            DataCell(Text(r["staff"]!)),
                            DataCell(
                              Text(
                                r["status"]!,
                                style: TextStyle(
                                  color: _getStatusColor(r["status"]!),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
          _buildNavItem(0, Icons.sports_soccer, "Menu"),
          _buildNavItem(1, Icons.refresh, "Return"),
          _buildNavItem(2, Icons.home, "Staff", largeIcon: true),
          _buildNavItem(3, Icons.history, "History"),
          _buildNavItem(4, Icons.logout, "Logout"),
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
    final bool isHovering = _hoverIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
      ),
    );
  }
}
