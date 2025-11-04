import 'package:flutter/material.dart';
import 'package:flutter_application_1/staff/request.dart';
import 'staff_history.dart';

// 1. Product Model to hold item data and the new return state
class Product {
  final String id;
  final String name;
  final String imagePath;
  final String status;
  final Color statusColor;
  bool
  isReturned; // New state field to track if the item has been virtually "returned"

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
  // Initial Product Data (Now managed in state)
  final List<Product> _products = [
    Product(
      id: "1",
      name: "Balls",
      imagePath: "asset/image/football.png",
      status: "Available",
      statusColor: Colors.green,
      isReturned: true,
    ),
    Product(
      id: "2",
      name: "Basketball",
      imagePath: "asset/image/basketball.png",
      status: "Borrowed",
      statusColor: Colors.blue,
      isReturned: false,
    ),
  ];

  // Function เปลี่ยน สี ปุ่ม Return/Returned
  void _toggleReturnStatus(String id) {
    setState(() {
      final productIndex = _products.indexWhere((p) => p.id == id);
      if (productIndex != -1) {
        _products[productIndex].isReturned =
            !_products[productIndex].isReturned;
      }
    });
  }

  // Function เปลี่ยน สี ปุ่ม Disable/Enable
  void _toggleDisable(String id) {
    setState(() {
      final productIndex = _products.indexWhere((p) => p.id == id);
      if (productIndex != -1) {
        _products[productIndex].isReturned =
            !_products[productIndex].isReturned;
      }
    });
  }

  // Function show pop  up เมื่อกด add กับ edit
  void _showProductDialog({
    required String title,
    required String productName,
    required String id,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: _ProductFormDialog(
          title: title,
          initialProductName: productName,
          id: id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          _showProductDialog(title: "Add Product", productName: "", id: "New");
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
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
                    const SizedBox(height: 16),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _StatBox(
                          color: Colors.purple,
                          label: "Total",
                          value: "10",
                        ),
                        _StatBox(
                          color: Colors.green,
                          label: "Available",
                          value: "5",
                        ),
                        _StatBox(
                          color: Colors.orange,
                          label: "Pending",
                          value: "3",
                        ),
                        _StatBox(
                          color: Colors.blue,
                          label: "Borrowed",
                          value: "2",
                        ),
                        _StatBox(
                          color: Colors.red,
                          label: "Disable",
                          value: "5",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Request",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Request(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.history,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "History",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StaffHistory(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Product List
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
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 1,
                            child: Text(
                              "ID",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Product",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Image",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Status",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Actions",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ..._products.map((product) {
                      return Column(
                        children: [
                          _ProductRow(
                            id: product.id,
                            name: product.name,
                            imagePath: product.imagePath,
                            status: product.status,
                            statusColor: product.statusColor,
                            isReturned: product.isReturned,
                            onEdit: () {
                              _showProductDialog(
                                title: "Edit Product",
                                productName: product.name,
                                id: product.id,
                              );
                            },
                            onToggleReturn: _toggleReturnStatus,
                            onToggleDisable: _toggleDisable,
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

// ------------------------- กล่อง Dashboard -------------------------
class _StatBox extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _StatBox({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------- Product Row -------------------------
class _ProductRow extends StatelessWidget {
  final String id;
  final String name;
  final String imagePath;
  final String status;
  final Color statusColor;
  final VoidCallback onEdit;
  final bool isReturned;
  final Function(String id) onToggleReturn;
  final Function(String id) onToggleDisable;

  const _ProductRow({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.status,
    required this.statusColor,
    required this.onEdit,
    required this.isReturned,
    required this.onToggleReturn,
    required this.onToggleDisable,
  });

  @override
  Widget build(BuildContext context) {
    final Color returnButtonColor = isReturned
        ? Colors.grey
        : Colors.purple.shade300;
    final String returnButtonLabel = isReturned ? "Returned" : "Return";

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
          Expanded(
            flex: 1,
            child: Text(
              id,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
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
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  icon: Icons.undo,
                  color: returnButtonColor,
                  label: returnButtonLabel,
                  onPressed: () => onToggleReturn(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------- MiniActionButton -------------------------
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
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(60, 28),
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

// ------------------------- Product Form Dialog -------------------------
class _ProductFormDialog extends StatelessWidget {
  final String title;
  final String initialProductName;
  final String id;

  const _ProductFormDialog({
    required this.title,
    required this.initialProductName,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController productNameController = TextEditingController(
      text: initialProductName,
    );

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
          Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.centerLeft,
            child: Text(
              "ID $id",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Product name",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: productNameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Image",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "Load Image",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Apply",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
