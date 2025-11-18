import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/staff/menu_staff.dart';
import 'package:flutter_application_1/staff/staff.dart';
import 'package:flutter_application_1/staff/staff_history.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:flutter_application_1/config/config.dart';

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
  int _notificationCount = 0; // สำหรับนับจำนวนแจ้งเตือน return

  // โหลดข้อมูล request จาก server
  Future<void> fetchRequests() async {
    try {
      final res = await http.get(
        Uri.parse("http://$defaultIp:$defaultPort/staff/request/${widget.staffId}"),
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
  Future<void> returnAsset(int requestId) async {
    try {
      final res = await http.put(
        Uri.parse("http://$defaultIp:$defaultPort/staff/returnAsset/$requestId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"staff_id": widget.staffId}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ คืนอุปกรณ์สำเร็จ")));

        // ✅ ลบแถวที่คืนแล้วออกจาก requests ใน UI
        setState(() {
          requests.removeWhere((r) => r['id'] == requestId);
        });

        // ✅ โหลด count แจ้งเตือนใหม่
        fetchNotificationCount();
      } else {
        String errorMessage = 'เกิดข้อผิดพลาดในการคืนอุปกรณ์';
        try {
          final errorBody = json.decode(res.body);
          errorMessage =
              errorBody['message'] ??
              'ข้อผิดพลาดไม่ทราบสาเหตุ (Status: ${res.statusCode})';
        } catch (e) {
          errorMessage = res.body.isNotEmpty
              ? res.body
              : 'Server Error (Status: ${res.statusCode})';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ คืนอุปกรณ์ไม่สำเร็จ: $errorMessage")),
        );
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

  // แจ้งเตือน
  Future<void> fetchNotificationCount() async {
    final res = await http.get(
      Uri.parse("http://$defaultIp:$defaultPort/api/returnCount"),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _notificationCount = data['count'] ?? 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRequests(); // โหลด request return
    fetchNotificationCount(); // ✅ โหลดจำนวนแจ้งเตือนเมื่อเปิดหน้า
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
            : RefreshIndicator(
                // <-- เพิ่ม RefreshIndicator
                onRefresh: fetchRequests, // ฟังก์ชันรีโหลด
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // ทำให้สามารถ scroll เพื่อ refresh ได้แม้ content น้อย
                  child: Column(children: [_buildHeader(), _buildTable()]),
                ),
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
                            ? Center(
                                child: SizedBox(
                                  height: 34,
                                  width: 90,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurpleAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () async {
                                      // --- Show Confirmation Dialog ---
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            "Confirm Return",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            "Are you sure you want to return '${r['name']}'?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurpleAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text("Confirm"),
                                            ),
                                          ],
                                        ),
                                      );

                                      // --- ถ้ากดยืนยัน ให้คืนของและลบแถว ---
                                      if (confirm == true) {
                                        returnAsset(
                                          r['id'],
                                        ); // คืนของและลบแถวใน UI
                                      }
                                    },
                                    child: const Text("Return"),
                                  ),
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
    final bool hasNotification =
        index == 1 && _notificationCount > 0; // ปุ่ม Return เท่านั้น

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          _onItemTapped(index);
          if (index == 1) {
            await http.delete(
              Uri.parse(
                "http://$defaultIp:$defaultPort/api/clearReturnNotifications",
              ),
            );
            setState(() => _notificationCount = 0);
          }
        },

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: largeIcon ? 42 : 28,
                  color: isSelected ? Colors.purple : Colors.black,
                ),
                if (hasNotification)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
