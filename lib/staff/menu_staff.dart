import 'package:flutter/material.dart';
import 'package:flutter_application_1/staff/request.dart';
import 'package:flutter_application_1/staff/staff.dart';
import 'package:flutter_application_1/staff/staff_history.dart';
import 'package:flutter_application_1/login/login.dart';

class MenuStaff extends StatefulWidget {
  final int staffId;
  final String username;

  const MenuStaff({super.key, required this.staffId, required this.username});

  @override
  State<MenuStaff> createState() => _MenuStaffState();
}

class _MenuStaffState extends State<MenuStaff> {
  int _selectedIndex = 0;
  int _hoverIndex = -1;

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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break; // already here
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Request()),
        );

        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Staff()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StaffHistory()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Welcome ${widget.username}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Sport Equipment",
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              ...equipmentList.map((item) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['status'],
                                style: TextStyle(
                                  color: getStatusColor(item['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: isBorrowEnabled(item['status'])
                                    ? () {}
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isBorrowEnabled(item['status'])
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
                  ),
                );
              }),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(isHovering ? 1.15 : 1.0),
        child: GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : isHovering
                      ? Colors.white.withOpacity(0.5)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: largeIcon ? 42 : 30,
                  color: isSelected
                      ? Colors.purple
                      : isHovering
                      ? Colors.deepPurple
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.purple
                      : isHovering
                      ? Colors.deepPurple
                      : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
