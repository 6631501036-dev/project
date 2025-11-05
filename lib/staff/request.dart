import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
        }
      } else {
        throw Exception("Failed to load data");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // 🔹 Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 20, bottom: 30),
                      color: Colors.lightBlue[100],
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, size: 30),
                              color: Colors.black,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.black12,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "${widget.username} (Staff)",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔹 Table
                    Container(
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
                                Expanded(
                                  child: Text(
                                    "ID",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Product",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Image",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Borrow Date",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Return Date",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          ...products.map((p) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${p['id']}",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "${p['name']}",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Image.network(
                                          "http://localhost:3000${p['imagePath']}",
                                          height: 40,
                                          width: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 30,
                                              ),
                                        ),
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
