import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/staff/menu_staff.dart';
import 'package:flutter_application_1/staff/staff.dart';
import 'package:flutter_application_1/staff/staff_history.dart';
import 'package:flutter_application_1/login/login.dart';

class Request extends StatefulWidget {
  final int staffId;
  final String username;

  const Request({super.key, required this.staffId, required this.username});

  @override
  State<Request> createState() => _RequestState();
}

class _RequestState extends State<Request> {
  List products = [];
  bool isLoading = true;
  int _hoverIndex = -1;
  int _selectedIndex = 1; // ✅ หน้า Request เป็นหน้า index 1

  // โหลดข้อมูล request ของ staff
  Future<void> fetchRequests() async {
    try {
      final res = await http.get(
        Uri.parse("http://192.168.234.1:3000/staff/request/${widget.staffId}"),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data["success"] == true) {
          setState(() {
            products = data["requests"];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ✅ ฟังก์ชันเปลี่ยนหน้า
  void _onItemTapped(int i) {
    setState(() => _selectedIndex = i);
    switch (i) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MenuStaff(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 1:
        // อยู่หน้า Request แล้ว
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                Staff(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StaffHistory(
              staffId: widget.staffId,
              username: widget.username,
            ),
          ),
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(children: [_buildHeader(), _buildTable()]),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.lightBlue[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.black12,
            child: Icon(Icons.person, size: 50, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.username} (Staff)",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Return / Request Page",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(child: Text("ID", textAlign: TextAlign.center)),
                Expanded(child: Text("Product", textAlign: TextAlign.center)),
                Expanded(
                  child: Text("Borrow Date", textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text("Return Date", textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          const Divider(),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No requests found",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...products.map((p) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text("${p['id']}", textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text(
                          "${p['name']}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${p['borrowDate'] ?? '-'}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${p['returnDate'] ?? '-'}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          _buildNavItem(2, Icons.add_circle_outline, "Add", largeIcon: true),
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
