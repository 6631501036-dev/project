import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_history.dart';
import 'student_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/login/login.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> with RouteAware {
  final String baseApi = "http://172.27.7.65:3000/api";
  int? borrowerId; // user_id
  List<Map<String, dynamic>> equipmentList = [];
  Map<String, dynamic>? _activeStatusItem;
  bool _loading = true;

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
      _activeStatusItem = null; // รีเซ็ตสถานะก่อนโหลด
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login again.")));
      }
      setState(() => _loading = false);
      return;
    }

    borrowerId = userId;

    try {
      // --- API ตัวที่ 1: เช็กสถานะ ---
      final statusUrl = Uri.parse('$baseApi/student/status/$userId');
      final statusResponse = await http
          .get(statusUrl)
          .timeout(const Duration(seconds: 10));

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        if (statusData != null) {
          setState(() {
            _activeStatusItem = statusData as Map<String, dynamic>;
          });
        }
      }

      // --- API ตัวที่ 2: ดึงรายการอุปกรณ์ ---
      final assetUrl = Uri.parse('$baseApi/student/asset?borrower_id=$userId');
      final assetResponse = await http
          .get(assetUrl)
          .timeout(const Duration(seconds: 10));

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
    // เช็กจากตัวแปร State ที่โหลดมา
    return _activeStatusItem != null;
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
        ).showSnackBar(const SnackBar(content: Text("Return request sent ✅")));
        await fetchAssets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request return failed: ${res.statusCode}")),
        );
      }
    } catch (e) {
      print("Return request error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network error while requesting return"),
          ),
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

  String buildImageUrl(String? imageField) {
    if (imageField == null || imageField.isEmpty) {
      return "http://172.27.7.65:3000/public/image/default.jpg";
    }
    if (imageField.startsWith("http")) return imageField;
    if (imageField.contains("/public/image")) {
      return "http://172.27.7.65:3000${imageField.startsWith('/') ? '' : '/'}$imageField";
    }
    return "http://172.27.7.65:3000/public/image/$imageField";
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
