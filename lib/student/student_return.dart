import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/config.dart';

class StudentReturn extends StatefulWidget {
  final int borrowerId;
  const StudentReturn({super.key, required this.borrowerId});

  @override
  State<StudentReturn> createState() => _StudentReturnState();
}

class _StudentReturnState extends State<StudentReturn> {
  List<Map<String, dynamic>> borrowedItems = [];
  final String baseUrl = "http://$defaultIp:$defaultPort";

  @override
  void initState() {
    super.initState();
    fetchBorrowedItems();
  }

  Future<void> fetchBorrowedItems() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/borrower/status/${widget.borrowerId}"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            borrowedItems = List<Map<String, dynamic>>.from(
              data['requests']?.where(
                    (r) => r['return_status'] == 'Not Returned',
                  ) ??
                  [],
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching borrowed items: $e");
    }
  }

  Future<void> returnItem(int requestId) async {
    try {
      // 💡 เปลี่ยนจาก http.delete เป็น http.put เพื่อเรียกใช้ endpoint ที่อัปเดต return_status ใน server/app.js
      final res = await http.put(
        Uri.parse("$baseUrl/borrower/return/$requestId"),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item returned successfully ✅")),
        );
        await fetchBorrowedItems();

        // แจ้งกลับ parent ว่าการคืนสำเร็จ (สำคัญสำหรับการรีเฟรชสถานะในหน้าหลัก)
        if (mounted) {
          Navigator.pop(context, true); // true = คืนสำเร็จ
        }
      } else {
        final response = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Return failed ❌ ${response['message'] ?? ''}"),
          ),
        );
      }
    } catch (e) {
      print("Return error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network error ❌")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Return Items")),
      body: RefreshIndicator(
        onRefresh: fetchBorrowedItems,
        child: borrowedItems.isEmpty
            ? const Center(child: Text("No items to return"))
            : ListView.builder(
                itemCount: borrowedItems.length,
                itemBuilder: (context, index) {
                  final item = borrowedItems[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Image.network(
                        "$baseUrl${item['image'] ?? ''}",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Image.asset("assets/default.jpg"),
                      ),
                      title: Text(item['asset_name'] ?? "Unknown"),
                      subtitle: Text(
                        "Borrow date: ${item['borrow_date'] ?? 'N/A'}\nReturn date: ${item['return_date'] ?? 'N/A'}",
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => returnItem(item['request_id']),
                        child: const Text("Return"),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
