import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'student_history.dart';
import 'student_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> with RouteAware {
  final String baseApi = "http://192.168.110.142:3000/api";
  int? borrowerId; // user_id
  List<Map<String, dynamic>> equipmentList = [];
  Map<String, dynamic>? _activeStatusItem;
  bool _loading = true;

  int canBorrowToday = 1;

  @override
  void initState() {
    super.initState();
    fetchAssets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    fetchAssets();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> fetchAssets() async {
    setState(() {
      _loading = true;
      _activeStatusItem = null;
      // รีเซ็ตสถานะก่อนโหลด
    });
    // default = 1
    // ========== ดึง user_id จาก token ==========
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'token');

    final jwt = JWT.decode(token!);
    Map playload = jwt.payload;

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login again.")));
      }
      setState(() => _loading = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
      return;
    }

    borrowerId = playload['user_id'] as int;

    try {
      // --- API ตัวที่ 1: เช็กสถานะ ---
      final statusUrl = Uri.parse('$baseApi/student/status/$borrowerId');
      final statusResponse = await http
          .get(statusUrl)
          .timeout(const Duration(seconds: 10));

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);

        setState(() {
          if (statusData != null) {
            canBorrowToday = statusData['can_borrow_today'] ?? 0;

            final String assetStatus = statusData['asset_status'] ?? '';
            _activeStatusItem =
                (assetStatus == 'Pending' || assetStatus == 'Borrowed') &&
                    statusData['return_status'] != 'Returned'
                ? statusData as Map<String, dynamic>
                : null;
          } else {
            canBorrowToday = 1; // default value
            _activeStatusItem = null;
          }
        });
      }

      // --- API ตัวที่ 2: ดึงรายการอุปกรณ์ ---
      final assetUrl = Uri.parse(
        '$baseApi/student/asset?borrower_id=$borrowerId',
      );
      final assetResponse = await http
          .get(assetUrl)
          .timeout(const Duration(seconds: 10));
      print("assetResponse: ${assetResponse.body}");

      if (assetResponse.statusCode == 200) {
        final data = jsonDecode(assetResponse.body);
        if (data['success'] == true) {
          setState(() {
            equipmentList = List<Map<String, dynamic>>.from(
              data['assets'] as List,
            );
          });
        } else {
          setState(() {
            equipmentList = [];
          });
        }
      } else {
        setState(() {
          equipmentList = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load assets: ${assetResponse.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("fetchAssets error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error while loading assets')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    }
  }

  Future<bool> _hasActiveRequest() async {
    if (_activeStatusItem == null) return false;

    final status = _activeStatusItem!['asset_status']?.toString();
    return status == 'Pending' || status == 'Borrowed';
  }

  Future<void> confirmBorrow(int assetId, String assetName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Borrow"),
        content: Text("Borrow $assetName for 7 days?"),
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

    if (confirm == true) {
      final blocked = await _hasActiveRequest();
      if (blocked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have an active request. Cannot borrow until completed.',
            ),
          ),
        );
        return;
      }
      borrowEquipment(assetId, assetName);
    }
  }

  Future<void> borrowEquipment(int assetId, String assetName) async {
    if (borrowerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No borrower ID found")));
      return;
    }

    final body = {
      "borrower_id": borrowerId.toString(),
      "asset_id": assetId.toString(),
      "borrow_date": DateTime.now().toString().substring(0, 10),
      "return_date": DateTime.now()
          .add(const Duration(days: 7))
          .toString()
          .substring(0, 10),
    };

    try {
      final res = await http
          .post(
            Uri.parse("$baseApi/student/borrow"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Borrow request sent ✅")));
        await fetchAssets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Borrow failed: ${res.statusCode}")),
        );
      }
    } catch (e) {
      print("Borrow error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network error while sending borrow request"),
          ),
        );
      }
    }
  }

  Future<void> requestReturn(int requestId, String assetName) async {
    try {
      final res = await http
          .put(Uri.parse("$baseApi/student/returnAsset/$requestId"))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Return successful ✅")));
        await fetchAssets(); // reload assets & status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Return failed: ${res.statusCode}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error during return")),
        );
      }
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
      case 'Requested Return':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  // อย่าลืมเปลี่ยน IP ด้วยเดี๋ยวรูปไม่ขึ้น
  final String imageBaseUrl = "http://192.168.110.142:3000";
  // อย่าลืมเปลี่ยน IP ด้วยเดี๋ยวรูปไม่ขึ้น
  // 🟢 แก้ไขฟังก์ชันนี้
  String buildImageUrl(String? imageField) {
    // 1. กรณีที่ไม่มีรูปภาพ (null หรือ empty)
    if (imageField == null || imageField.isEmpty) {
      return "$imageBaseUrl/public/image/default.jpg";
    } else {
      // 2. กรณีที่มีรูปภาพ
      return "$imageBaseUrl$imageField";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canReturn = false;
    int returnRequestId = 0;
    String returnAssetName = '';

    if (_activeStatusItem != null &&
        _activeStatusItem!['asset_status'] == 'Borrowed') {
      canReturn = true;
      returnRequestId = int.parse(_activeStatusItem!['request_id'].toString());
      returnAssetName = _activeStatusItem!['asset_name'] ?? 'Item';
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Sport Equipment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: fetchAssets,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 60),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ข้อความจำนวนที่สามารถยืมได้
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (canBorrowToday > 0)
                              Icon(Icons.book, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              "Can borrow today: $canBorrowToday",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      // Row ของปุ่ม 3 ปุ่ม
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Student_status(),
                                ),
                              ).then((_) => fetchAssets());
                            },
                            icon: const Icon(
                              Icons.manage_search_rounded,
                              color: Colors.black,
                            ),
                            label: const Text('Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade200,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Student_history(),
                                ),
                              ).then((_) => fetchAssets());
                            },
                            icon: const Icon(
                              Icons.history_rounded,
                              color: Colors.black,
                            ),
                            label: const Text('History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade200,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: canReturn
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Confirm Return"),
                                          content: Text(
                                            "Are you sure you want to return $returnAssetName?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                requestReturn(
                                                  returnRequestId,
                                                  returnAssetName,
                                                );
                                              },
                                              child: const Text("Yes, Return"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  : null,
                              icon: Icon(
                                Icons.assignment_return_outlined,
                                color: canReturn
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              label: Text(
                                'Return',
                                style: TextStyle(
                                  color: canReturn
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canReturn
                                    ? Colors.purple.shade400
                                    : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Column(
                        children: equipmentList.map((item) {
                          final String assetStatus =
                              (item['asset_status'] ?? 'Available').toString();
                          final bool isAvailable = (assetStatus == 'Available');

                          final String displayStatus = isAvailable
                              ? 'Available'
                              : 'Unavailable';
                          final Color statusColor = isAvailable
                              ? Colors.green
                              : Colors.grey;

                          final bool enableBorrow = isAvailable;

                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['asset_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          displayStatus,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: enableBorrow
                                              ? () {
                                                  confirmBorrow(
                                                    item['asset_id'],
                                                    item['asset_name'],
                                                  );
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: enableBorrow
                                                ? Colors.blue
                                                : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: const Text("Borrow"),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      buildImageUrl(item['image']?.toString()),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 60,
                                      ),
                                    ),
                                  ),
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
      ),
    );
  }
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
