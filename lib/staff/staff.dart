import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/staff/request.dart';
import 'package:flutter_application_1/staff/staff_history.dart';
import 'package:flutter_application_1/staff/menu_staff.dart';
import 'package:flutter_application_1/login/login.dart';

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
  const Staff({super.key});

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  int _selectedIndex = 0;
  int _hoverIndex = -1;

  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  // ✅ ดึงข้อมูลจาก Database ผ่าน API
  Future<void> _fetchAssets() async {
    try {
      final url = Uri.parse("http://192.168.234.1:3000/staff/assets");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          List<Product> loaded = [];
          for (var a in data["assets"]) {
            loaded.add(
              Product(
                id: a["asset_id"].toString(),
                name: a["asset_name"],
                imagePath:
                    "http://192.168.234.1:3000${a["image"]}", // ✅ โหลดรูปจาก backend
                status: a["asset_status"],
                statusColor: _getStatusColor(a["asset_status"]),
              ),
            );
          }
          setState(() {
            _products = loaded;
          });
        }
      } else {
        print("Failed to load assets: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching assets: $e");
    }
  }

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

  // ✅ Toggle Disable/Enable
  void _toggleDisable(String id) {
    setState(() {
      final productIndex = _products.indexWhere((p) => p.id == id);
      if (productIndex != -1) {
        _products[productIndex].isReturned =
            !_products[productIndex].isReturned;
      }
    });
  }

  // ✅ เพิ่มข้อมูลเข้า DB
  Future<void> _addAsset(
    String name,
    String description,
    File? imageFile,
  ) async {
    var uri = Uri.parse("http://192.168.234.1:3000/staff/addAsset");
    var request = http.MultipartRequest("POST", uri);
    request.fields["name"] = name;
    request.fields["description"] = description;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );
    }

    var response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Asset added successfully")),
      );
      _fetchAssets(); // โหลดข้อมูลใหม่
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Failed to add asset")));
    }
  }

  // ✅ ฟังก์ชันลบข้อมูล
  Future<void> _deleteAsset(String id) async {
    try {
      final url = Uri.parse("http://192.168.234.1:3000/staff/deleteAsset/$id");
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res["success"] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("🗑️ ${res["message"]}")));
          _fetchAssets(); // โหลดใหม่หลังลบ
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Failed: ${res["message"]}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error deleting asset: $e");
    }
  }

  void _showProductDialog({
    required String title,
    required String productName,
    required String id,
    bool isEdit = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: _ProductFormDialog(
          title: title,
          initialProductName: productName,
          id: id,
          onAddAsset: _addAsset,
          isEdit: isEdit,
        ),
      ),
    );
  }

  void _navigateToMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MenuStaff()),
    );
  }

  void _navigateToAdd() {
    _showProductDialog(title: "Add Product", productName: "", id: "New");
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StaffHistory()),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        _navigateToMenu();
        break;
      case 2:
        _navigateToAdd();
        break;
      case 3:
        _navigateToHistory();
        break;
      case 4:
        _logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔹 Bottom App Bar with Hover Animation
      bottomNavigationBar: Container(
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
            _buildNavItem(0, Icons.sports_soccer, "Sport\nEquipment"),
            _buildNavItem(1, Icons.refresh, "Return"),
            _buildNavItem(2, Icons.add_circle, "Add", largeIcon: true),
            _buildNavItem(3, Icons.history, "History"),
            _buildNavItem(4, Icons.logout, "Logout"),
          ],
        ),
      ),

      // 🔹 Main Body
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
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
                    const Text(
                      "John Doe (Staff)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Product Table
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
                            flex: 1,
                            child: Text("ID", textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text("Product", textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text("Image", textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text("Status", textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text("Actions", textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (_products.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "No data found...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._products.map((product) {
                        return Column(
                          children: [
                            _ProductRow(
                              id: product.id,
                              name: product.name,
                              imagePath: product.imagePath,
                              status: product.status,
                              statusColor: product.statusColor,
                              onEdit: () => _showProductDialog(
                                title: "Edit Product",
                                productName: product.name,
                                id: product.id,
                                isEdit: true, // ✅ Fix here
                              ),
                              onToggleDisable: _toggleDisable,
                              onDelete: _deleteAsset, // ✅ Add Delete
                              isReturned: product.isReturned,
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

  // 🔹 Bottom Nav Item
  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool largeIcon = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    final bool isHovering = _hoverIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(isHovering ? 1.15 : 1.0),
        child: GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : isHovering
                      ? Colors.white.withOpacity(0.5)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isHovering
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  size: largeIcon ? 42 : 30,
                  color: isSelected
                      ? Colors.purple
                      : isHovering
                      ? Colors.deepPurple
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.purple
                      : isHovering
                      ? Colors.deepPurple
                      : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🧩 Product Row
class _ProductRow extends StatelessWidget {
  final String id;
  final String name;
  final String imagePath;
  final String status;
  final Color statusColor;
  final VoidCallback onEdit;
  final Function(String id) onToggleDisable;
  final Function(String id) onDelete;
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
    final Color disableButtonColor = isReturned
        ? Colors.green
        : Colors.red.shade400;
    final String disableButtonLabel = isReturned ? "Enable" : "Disable";
    final IconData disableButtonIcon = isReturned ? Icons.check : Icons.block;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 1, child: Text(id, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(name, textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Center(
              child: CircleAvatar(
                backgroundImage: NetworkImage(imagePath),
                radius: 20,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _MiniActionButton(
                  icon: Icons.edit,
                  color: Colors.teal.shade300,
                  label: "Edit",
                  onPressed: onEdit,
                ),
                const SizedBox(height: 6),
                _MiniActionButton(
                  icon: disableButtonIcon,
                  color: disableButtonColor,
                  label: disableButtonLabel,
                  onPressed: () => onToggleDisable(id),
                ),
                const SizedBox(height: 6),
                _MiniActionButton(
                  icon: Icons.delete,
                  color: Colors.grey.shade700,
                  label: "Delete",
                  onPressed: () => onDelete(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🧩 Mini Action Button
class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _MiniActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85,
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }
}

// 🧩 Product Form Dialog
class _ProductFormDialog extends StatefulWidget {
  final String title;
  final String initialProductName;
  final String id;
  final bool isEdit;
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
  final TextEditingController productNameController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _updateAsset(String name, File? imageFile) async {
    try {
      var uri = Uri.parse(
        "http://192.168.234.1:3000/staff/editAsset/${widget.id}",
      );
      var request = http.MultipartRequest("PUT", uri);
      request.fields["name"] = name;
      request.fields["description"] = "Sport Equipment";

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile.path),
        );
      }

      var response = await request.send();
      var resBody = await response.stream.bytesToString();
      var resJson = jsonDecode(resBody);

      if (response.statusCode == 200 && resJson["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Asset updated successfully")),
        );
        (context.findAncestorStateOfType<_StaffState>())
            ?._fetchAssets(); // ✅ reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${resJson["message"] ?? ''}")),
        );
      }
    } catch (e) {
      print("Error updating asset: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    productNameController.text = widget.initialProductName;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.isEdit ? "Edit Asset ID ${widget.id}" : "Add New Asset",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Product name",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: productNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Image",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _pickImage,
                  child: const Text("📸 Choose Image"),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.file(_selectedImage!, height: 100),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final name = productNameController.text.trim();
                    if (name.isEmpty) return;

                    if (widget.isEdit) {
                      await _updateAsset(name, _selectedImage);
                    } else {
                      await widget.onAddAsset(
                        name,
                        "Sport Equipment",
                        _selectedImage,
                      );
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(widget.isEdit ? "Save Changes" : "Apply"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
