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
  List requests = [];
  bool isLoading = true;
  bool isError = false;
  int _hoverIndex = -1;
  int _selectedIndex = 1;

  // โหลดข้อมูล request จาก server
  Future<void> fetchRequests() async {
    try {
      final res = await http.get(
        Uri.parse("http://192.168.234.1:3000/staff/request/${widget.staffId}"),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data["success"] == true) {
          setState(() {
            requests = data["requests"];
            isLoading = false;
            isError = false;
          });
        } else {
          setState(() {
            isError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  // ✅ ฟังก์ชันคืนของ (PUT)
  // request.dart (ในฟังก์ชัน Future<void> returnAsset(int requestId))
  // ✅ ฟังก์ชันคืนของ (PUT)
  Future<void> returnAsset(int requestId) async {
    try {
      final res = await http.put(
        Uri.parse("http://192.168.234.1:3000/staff/returnAsset/$requestId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"staff_id": widget.staffId}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ คืนอุปกรณ์สำเร็จ")));
        fetchRequests(); // โหลดใหม่หลังคืนสำเร็จ
      } else {
        // --- ส่วนที่แก้ไข: จัดการข้อความผิดพลาดให้ชัดเจนขึ้น ---
        String errorMessage = 'เกิดข้อผิดพลาดในการคืนอุปกรณ์';
        try {
          final errorBody = json.decode(res.body);
          // ดึง message จาก Server (เช่น "Request not found or already returned")
          errorMessage =
              errorBody['message'] ??
              'ข้อผิดพลาดไม่ทราบสาเหตุ (Status: ${res.statusCode})';
        } catch (e) {
          // หาก Server ไม่ได้ส่ง JSON ที่ถูกต้องกลับมา
          errorMessage = res.body.isNotEmpty
              ? res.body
              : 'Server Error (Status: ${res.statusCode})';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ คืนอุปกรณ์ไม่สำเร็จ: $errorMessage")),
        );
        // ----------------------------------------------------
      }
    } catch (e) {
      debugPrint("Error PUT returnAsset: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์"),
        ),
      );
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

  // ฟังก์ชันแปลงวันที่ (ตัดเวลาออก)
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      return DateTime.parse(dateString).toLocal().toString().split(' ')[0];
    } catch (_) {
      return dateString.split(' ')[0]; // fallback ถ้า format ไม่ตรง
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
            : isError
            ? _buildErrorView()
            : SingleChildScrollView(
                child: Column(children: [_buildHeader(), _buildTable()]),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 150,
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
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 10),
          const Text("ไม่สามารถโหลดข้อมูลได้", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                isError = false;
              });
              fetchRequests();
            },
            child: const Text("ลองอีกครั้ง"),
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
                Expanded(child: Text("Status", textAlign: TextAlign.center)),
                Expanded(child: Text("Action", textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No requests found",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...requests.map((r) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${r['id']}",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${r['name']}",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatDate(r['borrowDate']),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatDate(r['returnDate']),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${r['returnStatus'] ?? '-'}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: (r['returnStatus'] == 'Requested Return')
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                ),
                                onPressed: () => returnAsset(r['id']),
                                child: const Text(
                                  "Return",
                                  style: TextStyle(color: Colors.black),
                                ),
                              )
                            : const Text(
                                "-",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
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

  // ส่วนของ Bottom Navigation Bar
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
