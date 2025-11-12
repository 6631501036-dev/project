import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/staff/request.dart';
import 'package:flutter_application_1/staff/staff_history.dart';
import 'package:flutter_application_1/staff/menu_staff.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ✅ Class สำหรับข้อมูลสินทรัพย์
class Product {
  final String id;
  final String name;
  final String imagePath;
  final String status;
  final Color statusColor;
  bool isReturned;

  Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.status,
    required this.statusColor,
    this.isReturned = false,
  });
}

class Staff extends StatefulWidget {
  final int staffId;
  final String username;

  const Staff({super.key, required this.staffId, required this.username});

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  int _selectedIndex = 2;
  int _hoverIndex = -1;
  int notificationCount = 0; // เพิ่มตัวแปรแจ้งเตือน
  List<Product> _products = [];

  //ตัวแปร state เก็บสรุป
  int totalAssets = 0;
  int availableCount = 0;
  int pendingCount = 0;
  int borrowedCount = 0;
  int disabledCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAssets(); // โหลดข้อมูล assets
    _fetchDashboardData(); //โหลดข้อมูล Dashboard
    _fetchNotifications(); //เรียกใช้ แจ้งเตือน
  }

  // ✅ โหลดข้อมูลสินทรัพย์จากฐานข้อมูล
  Future<void> _fetchAssets() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // ❌ แก้ไข IP Address ให้ถูกต้อง หากมีการเปลี่ยนแปลง
      final url = Uri.parse("http://192.168.110.142:3000/assets");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assets = data['assets'] as List;
        setState(() {
          _products = assets
              .map(
                (item) => Product(
                  id: item['asset_id'].toString(),
                  name: item['asset_name'],
                  imagePath:
                      // ❌ แก้ไข IP Address ให้ถูกต้อง
                      "http://192.168.110.142:3000${item['image'] ?? '/public/image/default.jpg'}",
                  status: item['asset_status'],
                  statusColor: _getStatusColor(item['asset_status']),
                ),
              )
              .toList();

          // คำนวณสถิติจาก _products
          totalAssets = _products.length;
          availableCount = _products
              .where((p) => p.status == "Available")
              .length;
          pendingCount = _products.where((p) => p.status == "Pending").length;
          borrowedCount = _products.where((p) => p.status == "Borrowed").length;
          disabledCount = _products.where((p) => p.status == "Disabled").length;
        });
        print("✅ Assets loaded: ${_products.length}");
      } else {
        print("❌ Failed to load assets: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching assets: $e");
    }
  }

  // ✅ กำหนดสีตามสถานะ
  Color _getStatusColor(String status) {
    switch (status) {
      case "Available":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Borrowed":
        return Colors.blue;
      case "Disabled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ เพิ่มสินทรัพย์ใหม่
  Future<void> addAsset(String name, String description, [File? image]) async {
    try {
      // ❌ แก้ไข IP Address ให้ถูกต้อง
      final uri = Uri.parse('http://192.168.110.142:3000/staff/addAsset');
      var request = http.MultipartRequest('POST', uri);
      request.fields['name'] = name;
      request.fields['description'] = description;
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (response.statusCode == 200 && data['success'] == true) {
        _showPopup("Success", data['message'], true);
        _fetchAssets(); // reload assets
      } else {
        _showPopup("Error", data['message'] ?? 'Something went wrong', false);
      }
    } catch (e) {
      _showPopup("Error", e.toString(), false);
    }
  }

  // ✅ เพิ่มฟังก์ชันแก้ไขสินทรัพย์
  Future<void> _editAsset(String id, String name, [File? image]) async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      // ❌ แก้ไข IP Address ให้ถูกต้อง
      final uri = Uri.parse('http://192.168.110.142:3000/staff/editAsset/$id');
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token'; // เพิ่ม token
      request.fields['name'] = name;
      // Note: 'description' is assumed to be required by the backend, even if not editable here.
      request.fields['description'] =
          "Sport Equipment"; // ใช้ค่า default หรือดึงจาก product เดิมถ้ามี

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (response.statusCode == 200 && data['success'] == true) {
        _showPopup(
          "Success",
          data['message'],
          true,
          onApply: _fetchAssets,
        ); // reload assets
      } else {
        _showPopup("Error", data['message'] ?? 'Failed to update asset', false);
      }
    } catch (e) {
      _showPopup("Error", "Error updating asset: $e", false);
    }
  }

  // ✅ แสดง Popup แจ้งเตือน
  void _showPopup(
    String title,
    String message,
    bool success, {
    VoidCallback? onApply,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: success ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: success ? Colors.green : Colors.red,
                child: Icon(
                  success ? Icons.check : Icons.error_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ใช้ปุ่มเดียวเพื่อปิด
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"), // เปลี่ยนเป็น Close
                  ),
                  // Removed 'Apply' button for standard success/error popups
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 ฟังก์ชันสลับสถานะ (Enable/Disable) เชื่อมกับ API server
  Future<void> _toggleAssetStatus(String assetId, String currentStatus) async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // กำหนด endpoint ตาม currentStatus
      final endpoint = currentStatus == "Disabled"
          ? "enable" // Disabled -> Enable
          : "disable"; // Available -> Disable

      final url = Uri.parse(
        "http://192.168.110.142:3000/staff/editAsset/$assetId/$endpoint",
      );

      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _fetchAssets(); // โหลดข้อมูลใหม่
          _showPopup("Success", data['message'] ?? "Status updated", true);
        } else {
          _showPopup(
            "Error",
            data['message'] ?? "Failed to change status",
            false,
          );
        }
      } else {
        final data = json.decode(response.body);
        _showPopup(
          "Error",
          data['message'] ?? "Failed to change status",
          false,
        );
      }
    } catch (e) {
      _showPopup("Error", "Error toggling status: $e", false);
    }
  }

  // ✅ ลบสินทรัพย์
  Future<void> _deleteAsset(String id) async {
    // เพิ่มการยืนยันก่อนลบ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this asset?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final storage = FlutterSecureStorage();
        final token = await storage.read(key: 'token');
        // ❌ แก้ไข IP Address ให้ถูกต้อง
        final url = Uri.parse(
          "http://192.168.110.142:3000/staff/deleteAsset/$id",
        );
        final response = await http.delete(
          url,
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          _fetchAssets();
          _showPopup("Success", "Asset deleted successfully", true);
        } else {
          final data = json.decode(response.body);
          _showPopup(
            "Error",
            data['message'] ?? 'Failed to delete asset',
            false,
          );
        }
      } catch (e) {
        _showPopup("Error", "Error deleting asset: $e", false);
      }
    }
  }

  // ✅ การจัดการการแตะ Bottom Navigation Bar
  void _onItemTapped(int i) {
    setState(() => _selectedIndex = i);
    switch (i) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MenuStaff(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 1:
        _clearReturnNotifications(); // ล้างแจ้งเตือนก่อนเปิดหน้า
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                Request(staffId: widget.staffId, username: widget.username),
          ),
        );
        break;
      case 2:
        // Case 2: Add Asset (เปิด Dialog)
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: _ProductFormDialog(
              title: "Add Asset",
              initialProductName: "",
              id: "",
              onAddAsset: (name, _, image) =>
                  addAsset(name, "Sport Equipment", image), // ใช้ addAsset เดิม
            ),
          ),
        );
        break;
      case 3:
        Navigator.push(
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

  // ✅ เปิด Dialog สำหรับแก้ไข
  void _showEditDialog(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: _ProductFormDialog(
          title: "Edit Asset",
          initialProductName: product.name,
          id: product.id,
          isEdit: true, // ตั้งเป็นโหมดแก้ไข
          onAddAsset: (name, _, image) =>
              _editAsset(product.id, name, image), // ใช้ _editAsset
        ),
      ),
    );
  }

  // ✅ Dashboard Data API
  Future<void> _fetchDashboardData() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      // ✅ แก้ URL ให้ถูก
      final url = Uri.parse(
        'http://192.168.110.142:3000/staff/dashboard/${widget.staffId}',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["success"] == true && data["data"] != null) {
          setState(() {
            totalAssets = data["data"]["total_assets"] ?? 0;
            availableCount = data["data"]["available_assets"] ?? 0;
            borrowedCount = data["data"]["borrowed_assets"] ?? 0;
            pendingCount = data["data"]["pending_requests"] ?? 0;
            disabledCount = _products
                .where((p) => p.status == "Disabled")
                .length; // หรือเปลี่ยนชื่อ field ตามที่ backend ส่งมา
          });
        } else {
          print("⚠️ Dashboard API returned success=false or no data");
        }
      } else {
        print("❌ Dashboard API failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching dashboard data: $e");
    }
  }

  // ✅ ฟังก์ชันโหลดจำนวนแจ้งเตือน
  Future<void> _fetchNotifications() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final url = Uri.parse("http://192.168.110.142:3000/api/returnCount");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // ถ้า backend ต้องการ
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notificationCount = data['count'] ?? 0;
        });
      } else {
        print("❌ Failed to fetch notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching notifications: $e");
    }
  }

  // ✅ ล้างแจ้งเตือนแจ้งเตือน
  Future<void> _clearReturnNotifications() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final url = Uri.parse(
        "http://192.168.110.142:3000/api/clearReturnNotifications",
      );
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          notificationCount = 0; // ล้าง badge ทันที
        });
        print("✅ Notifications cleared");
      } else {
        print("❌ Failed to clear notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error clearing notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNavBar(),
      body: SafeArea(
        // 2. ✅ เพิ่ม RefreshIndicator
        child: RefreshIndicator(
          onRefresh:
              _fetchAssets, // เรียกฟังก์ชันโหลดข้อมูลเมื่อ Pull-to-refresh
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // ทำให้ดึงลงได้เสมอ
            child: Column(children: [_buildHeader(), _buildTable()]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.lightBlue[100],
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.black12,
            child: Icon(Icons.person, size: 50, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.username}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "(Staff)",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),

          // ✅ เพิ่ม Dashboard ที่นี่
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard("Total", totalAssets, Colors.purple),
                _buildStatCard("Available", availableCount, Colors.green),
                _buildStatCard("Pending", pendingCount, Colors.orange),
                _buildStatCard("Borrowed", borrowedCount, Colors.blue),
                _buildStatCard("Disable", disabledCount, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 ย้ายฟังก์ชัน statCard มาแยกออกไว้ใช้ใน Header
  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
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
                Expanded(child: Text("Image", textAlign: TextAlign.center)),
                Expanded(child: Text("Status", textAlign: TextAlign.center)),
                Expanded(child: Text("Actions", textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(),
          ..._products.map((p) {
            return Column(
              children: [
                _ProductRow(
                  id: p.id,
                  name: p.name,
                  imagePath: p.imagePath,
                  status: p.status,
                  statusColor: p.statusColor,
                  isReturned: p.isReturned,
                  onEdit: () =>
                      _showEditDialog(p), // ✅ ผูกกับฟังก์ชันเปิด Dialog แก้ไข
                  onToggleDisable: (id) => _toggleAssetStatus(
                    id,
                    p.status,
                  ), // 1. ✅ ผูกกับฟังก์ชันสลับสถานะและส่ง status ปัจจุบัน
                  onDelete: _deleteAsset,
                ),
                const Divider(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
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

    // ตรวจสอบถ้าเป็นไอคอน Notifications (สมมติว่า index 1)
    bool showBadge = index == 1 && notificationCount > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
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
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (showBadge)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationCount.toString(),
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
      ),
    );
  }
}

// ✅ Widget แถวข้อมูลสินทรัพย์
class _ProductRow extends StatelessWidget {
  final String id, name, imagePath, status;
  final Color statusColor;
  final VoidCallback onEdit;
  final Function(String) onToggleDisable;
  final Function(String) onDelete;
  final bool isReturned;

  const _ProductRow({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.status,
    required this.statusColor,
    required this.onEdit,
    required this.onToggleDisable,
    required this.onDelete,
    required this.isReturned,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ✅ กำหนดข้อความและสีปุ่ม Disable/Enable
    final bool isDisabled = status == "Disabled";
    final String toggleButtonText = isDisabled ? "Enable" : "Disable";
    final Color toggleButtonColor = isDisabled
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Row(
      children: [
        Expanded(child: Text(id, textAlign: TextAlign.center)),
        Expanded(child: Text(name, textAlign: TextAlign.center)),
        Expanded(
          child: Center(
            child: CircleAvatar(
              backgroundImage: NetworkImage(imagePath),
              radius: 20,
            ),
          ),
        ),
        Expanded(
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Edit ปุ่มสีน้ำเงิน
              ElevatedButton(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 35), // กำหนดความกว้างและสูง
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Edit",
                  style: TextStyle(fontSize: 12),
                ), // ขนาดปุ่ม
              ),
              const SizedBox(height: 6),
              // Enable/Disable ปุ่มสีเขียว/แดง
              ElevatedButton(
                onPressed: () => onToggleDisable(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: toggleButtonColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  toggleButtonText,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(height: 6),
              // Delete ปุ่มสีเทา
              ElevatedButton(
                onPressed: () => onDelete(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Delete", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ✅ Widget Dialog สำหรับเพิ่ม/แก้ไขสินทรัพย์
class _ProductFormDialog extends StatefulWidget {
  final String title, initialProductName, id;
  final bool isEdit;
  // 2. ✅ แก้ไข onAddAsset/onEditAsset ให้รองรับการทำงานแบบเดียวกัน
  final Future<void> Function(String, String, File?) onAddAsset;

  const _ProductFormDialog({
    required this.title,
    required this.initialProductName,
    required this.id,
    required this.onAddAsset,
    this.isEdit = false,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final TextEditingController controller = TextEditingController();
  File? image;
  bool _isLoading = false; // สำหรับป้องกันกดซ้ำ

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialProductName;
  }

  // เลือกรูปภาพ
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  // แสดง Popup
  void _showPopup(String title, String message, bool success) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // เรียก onAddAsset พร้อม handle success/fail
  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await widget.onAddAsset(controller.text, "Sport Equipment", image);
      _showPopup(
        "Success",
        widget.isEdit
            ? "Asset updated successfully"
            : "Asset added successfully",
        true,
      );
      Navigator.pop(context); // ปิด dialog หลัง success
    } catch (e) {
      _showPopup("Error", e.toString(), false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Product name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: Text(widget.isEdit ? "Change Image" : "Choose Image"),
            ),
            if (image != null) ...[
              const SizedBox(height: 10),
              Image.file(image!, height: 100),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
                // Save/Add
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isEdit
                        ? Colors.lightGreen
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(widget.isEdit ? "Save Changes" : "Add Asset"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
