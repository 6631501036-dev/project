import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'student_history.dart';
import 'student_status.dart';
import 'package:intl/intl.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  int? borrowerId;
  String? username;
  String? profileImageUrl;
  int borrowedToday = 0; // จำนวนที่ยืมแล้ววันนี้
  List<Map<String, dynamic>> equipmentList = [];
  final String baseUrl = "http://192.168.234.1:3000";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storage = await SharedPreferences.getInstance();
    final token = storage.getString('token');
    final savedName = storage.getString('username');

    if (token != null) {
      final data = json.decode(token);
      setState(() {
        borrowerId = data['user_id'];
        username = savedName ?? data['username'] ?? "Student";
        profileImageUrl = "$baseUrl/profile/${data['user_id']}.jpg";
      });
      await fetchAssets();
      await fetchBorrowedCount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found, please login again")),
      );
    }
  }

  // ดึงจำนวนที่ยืมแล้ววันนี้
  Future<void> fetchBorrowedCount() async {
    if (borrowerId == null) return;
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/borrower/borrow_count?borrower_id=$borrowerId"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            borrowedToday = data['count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Error fetching borrow count: $e");
    }
  }

  Future<void> fetchAssets() async {
    if (borrowerId == null) return;
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/asset?borrower_id=$borrowerId"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            equipmentList = List<Map<String, dynamic>>.from(data['assets']);
          });
        }
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  // ✅ Popup เมื่อกดยืม
  Future<void> confirmBorrow(int assetId, String assetName) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final borrowDate = DateFormat('yyyy-MM-dd').format(now);
    final returnDate = DateFormat('yyyy-MM-dd').format(tomorrow);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Borrow"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Do you want to borrow $assetName?"),
            const SizedBox(height: 10),
            Text("Borrow date: $borrowDate"),
            Text("Return date: $returnDate"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) borrowEquipment(assetId, assetName, returnDate);
  }

  // ✅ ฟังก์ชันยืมของ
  Future<void> borrowEquipment(
    int assetId,
    String assetName,
    String returnDate,
  ) async {
    if (borrowerId == null) return;

    // ถ้ายืมครบ 1 ชิ้นแล้ว ห้ามยืมเพิ่ม
    if (borrowedToday >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can borrow only 1 item per day ❌"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final body = {
      "borrower_id": borrowerId,
      "asset_id": assetId,
      "return_date": returnDate,
    };

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/borrower/borrow"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      final response = jsonDecode(res.body);

      if (res.statusCode == 200 && response['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Borrow request sent ✅")));
        await fetchAssets();
        await fetchBorrowedCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Borrow failed ❌ ${response['message'] ?? ''}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Borrow error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network error ❌")));
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Borrowed':
        return Colors.teal;
      case 'Pending':
        return Colors.orange;
      case 'Disabled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F3FF),
      appBar: AppBar(
        title: const Text("Sport Equipment"),
        backgroundColor: Colors.blue.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final storage = await SharedPreferences.getInstance();
              await storage.remove('token');
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: borrowerId == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchAssets();
                await fetchBorrowedCount();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 🔹 โปรไฟล์ผู้ใช้ + จำนวนที่ยืมได้
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(profileImageUrl!),
                            onBackgroundImageError: (_, __) =>
                                const Icon(Icons.person, size: 40),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username ?? "Student",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Available to borrow: ${borrowedToday < 1 ? 1 - borrowedToday : 0}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: borrowedToday < 1
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // 🔹 ปุ่ม Status & History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Student_status(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.manage_search_rounded),
                            label: const Text('Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade200,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentHistory(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history_rounded),
                            label: const Text('History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade200,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🔹 รายการอุปกรณ์
                      Column(
                        children: equipmentList.map((item) {
                          final status = item['asset_status'] ?? 'Available';
                          final enableBorrow =
                              status == 'Available' && borrowedToday < 1;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  "$baseUrl${item['image']}",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                              title: Text(item['asset_name'] ?? ''),
                              subtitle: Text(
                                status,
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: enableBorrow
                                    ? () => confirmBorrow(
                                        item['asset_id'],
                                        item['asset_name'],
                                      )
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: enableBorrow
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text("Borrow"),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
