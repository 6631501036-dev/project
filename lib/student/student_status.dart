// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class Student_status extends StatefulWidget {
//   const Student_status({super.key});

//   @override
//   State<Student_status> createState() => _Student_statusState();
// }

// class _Student_statusState extends State<Student_status> {
//   final String baseUrl = "http://192.168.234.1:3000";
//   int? borrowerId;
//   String? username;
//   bool _loading = true;
//   List<Map<String, dynamic>> _requests = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }

//   Future<void> _loadUser() async {
//     final storage = await SharedPreferences.getInstance();
//     final token = storage.getString('token');
//     if (token == null) return;

//     final data = json.decode(token);
//     setState(() {
//       borrowerId = data['user_id'];
//       username = data['username'] ?? "Guest";
//     });

//     fetchStatus();
//   }

//   Future<void> fetchStatus() async {
//     if (borrowerId == null) return;
//     setState(() => _loading = true);

//     try {
//       final res = await http.get(
//         Uri.parse("$baseUrl/borrower/status/$borrowerId"),
//       );
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data['success'] == true) {
//           setState(() {
//             _requests = List<Map<String, dynamic>>.from(data['requests']);
//           });
//         }
//       }
//     } catch (e) {
//       print("Status fetch error: $e");
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> returnItem(int requestId, String assetName) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Return Equipment"),
//         content: Text("Confirm return for $assetName?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Yes"),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       final res = await http.delete(
//         Uri.parse("$baseUrl/borrower/return/$requestId"),
//       );
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data['message'] ?? "Returned ✅")),
//         );
//         fetchStatus();
//       } else {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Return failed ❌")));
//       }
//     } catch (e) {
//       print("Return error: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Connection error ❌")));
//     }
//   }

//   Color _getColor(String status) {
//     switch (status) {
//       case 'Available':
//         return Colors.green;
//       case 'Borrowed':
//         return Colors.teal;
//       case 'Pending':
//         return Colors.orange;
//       default:
//         return Colors.black;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFE8F3FF),
//       appBar: AppBar(
//         title: Text(username ?? "Guest"),
//         backgroundColor: Colors.blue.shade200,
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: fetchStatus),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _requests.isEmpty
//           ? const Center(child: Text("No borrowed items"))
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _requests.length,
//               itemBuilder: (context, index) {
//                 final item = _requests[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         "$baseUrl${item['image'] ?? '/public/image/default.jpg'}",
//                         width: 60,
//                         height: 60,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) =>
//                             const Icon(Icons.broken_image, size: 40),
//                       ),
//                     ),
//                     title: Text(item['asset_name'] ?? ''),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Status: ${item['asset_status']}",
//                           style: TextStyle(
//                             color: _getColor(item['asset_status']),
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           "Borrowed: ${item['borrow_date'] ?? '-'} → ${item['return_date'] ?? '-'}",
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ],
//                     ),
//                     trailing: ElevatedButton(
//                       onPressed: () =>
//                           returnItem(item['request_id'], item['asset_name']),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red.shade300,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: const Text("Return"),
//                     ),
//                    ),
//                 );
//               },
//             ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentStatus extends StatefulWidget {
  final int borrowerId;
  const StudentStatus({super.key, required this.borrowerId});

  @override
  State<StudentStatus> createState() => _StudentStatusState();
}

class _StudentStatusState extends State<StudentStatus> {
  List<Map<String, dynamic>> borrowedItems = [];
  final String baseUrl = "http://192.168.234.1:3000";

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/borrower/status/${widget.borrowerId}"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            borrowedItems = List<Map<String, dynamic>>.from(
              data['requests'] ?? [],
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching status: $e");
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
      appBar: AppBar(title: const Text("Borrow Status")),
      body: RefreshIndicator(
        onRefresh: fetchStatus,
        child: borrowedItems.isEmpty
            ? const Center(child: Text("No borrowed items"))
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
                        "Status: ${item['asset_status'] ?? 'Available'}\nApproval: ${item['approval_status'] ?? 'N/A'}\nReturn: ${item['return_status'] ?? 'N/A'}",
                      ),
                      textColor: getStatusColor(
                        item['asset_status'] ?? 'Available',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
