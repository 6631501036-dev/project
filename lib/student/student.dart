import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_history.dart';
import 'student_status.dart';

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> with RouteAware {
  final int borrowerId = 1;
  List<Map<String, dynamic>> equipmentList = [];

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
    try {
      final res = await http.get(
        Uri.parse("http://172.28.147.41:3000/api/student/asset"),
      );

      if (res.statusCode == 200) {
        setState(() {
          equipmentList = List<Map<String, dynamic>>.from(
            jsonDecode(res.body)['assets'],
          );
        });
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> confirmBorrow(int assetId, String assetName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Borrow"),
        content: Text("Borrow $assetName?"),
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
      borrowEquipment(assetId, assetName);
    }
  }

  Future<void> borrowEquipment(int assetId, String assetName) async {
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
      final res = await http.post(
        Uri.parse("http://172.28.147.41:3000/api/student/borrow"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 200 ? "Borrow request sent ✅" : "Borrow failed ❌",
          ),
        ),
      );

      if (res.statusCode == 200) fetchAssets();
    } catch (e) {
      print("Borrow error: $e");
    }
  }

  Future<void> requestReturn(int requestId, String assetName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Return"),
        content: Text("Return $assetName?"),
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
      submitReturnRequest(requestId, assetName);
    }
  }

  Future<void> submitReturnRequest(int requestId, String assetName) async {
    try {
      final res = await http.put(
        Uri.parse(
          "http://172.28.147.41:3000/api/student/returnAsset/$requestId",
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 200 ? "Return request sent ✅" : "Return failed ❌",
          ),
        ),
      );

      if (res.statusCode == 200) fetchAssets();
    } catch (e) {
      print("Return error: $e");
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
      appBar: AppBar(
        title: const Text(
          'Sport Equipment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchAssets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Student_history(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade200,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Column(
                  children: equipmentList.map((item) {
                    final status = item['asset_status'] ?? 'Available';
                    final requestId = item['request_id'] ?? 0;
                    final itemBorrowerId = item['borrower_id'] ?? 0;
                    final returnStatus =
                        item['return_status'] ?? 'Not Returned';

                    final enableBorrow = status == 'Available';
                    final enableReturn =
                        status == 'Borrowed' &&
                        itemBorrowerId == borrowerId &&
                        returnStatus == 'Not Returned';
                    final isReturnRequested =
                        returnStatus == 'Requested Return';

                    final imageFile = item['image'] ?? "";

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: getStatusColor(status),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed:
                                        (enableBorrow || enableReturn) &&
                                            !isReturnRequested
                                        ? () {
                                            if (enableBorrow) {
                                              confirmBorrow(
                                                item['asset_id'],
                                                item['asset_name'],
                                              );
                                            } else if (enableReturn &&
                                                requestId != 0) {
                                              requestReturn(
                                                requestId,
                                                item['asset_name'],
                                              );
                                            }
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: enableReturn
                                          ? (isReturnRequested
                                                ? Colors.grey
                                                : Colors.purple)
                                          : enableBorrow
                                          ? Colors.blue
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      enableReturn ? "Return" : "Borrow",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                "http://172.28.147.41:3000$imageFile"
                                    .replaceAll(' ', '%20'),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
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
