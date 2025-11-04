import 'package:flutter/material.dart';
import 'lender_history.dart';

// Product Model
class Product {
  final String id;
  final String name;
  final String imagePath;
  String loanStatus;

  Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.loanStatus,
  });
}

class Lender extends StatefulWidget {
  const Lender({super.key});

  @override
  State<Lender> createState() => _LenderState();
}

class _LenderState extends State<Lender> {
  final List<Product> _products = [
    Product(
      id: "1",
      name: "Football",
      imagePath: "asset/image/football.png",
      loanStatus: "Pending",
    ),
    Product(
      id: "2",
      name: "Basketball",
      imagePath: "asset/image/basketball.png",
      loanStatus: "Pending",
    ),
  ];

  void _updateLoanStatus(String id, String newStatus) {
    if (newStatus == "Disapprove") {
      TextEditingController reasonController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Disapprove Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide a reason for disapproval:"),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Enter reason...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                String reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a reason for disapproval."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() {
                  final index = _products.indexWhere((p) => p.id == id);
                  if (index != -1) {
                    _products[index].loanStatus = "Disapproved";
                    // You can store the reason somewhere if needed
                    // e.g., _products[index].reason = reason;
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Item disapproved. Reason: $reason"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      );
    } else {
      // Default confirmation for approve
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Approve Confirmation"),
          content: const Text("Are you sure you want to approve this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  final index = _products.indexWhere((p) => p.id == id);
                  if (index != -1) {
                    _products[index].loanStatus = "Borrowed";
                  }
                });
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                color: Colors.lightBlue[100],
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.person, size: 50, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "John Doe (Lender)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.history, color: Colors.white),
                        label: const Text(
                          "History",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LenderHistory(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Product List
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 5,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
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

                    // Product rows
                    ..._products.map((product) {
                      return Column(
                        children: [
                          _ProductRow(
                            id: product.id,
                            name: product.name,
                            imagePath: product.imagePath,
                            loanStatus: product.loanStatus,
                            onEdit: () {},
                            onStatusChanged: _updateLoanStatus,
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
        color: Colors.white, // พื้นหลังสีขาว
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
              fontSize: 20, // ขนาดใหญ่ขึ้น
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
  final String loanStatus;
  final VoidCallback onEdit;
  final Function(String id, String newStatus) onStatusChanged;

  const _ProductRow({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.loanStatus,
    required this.onEdit,
    required this.onStatusChanged,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Borrowed':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Disapproved':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Borrowed':
        return Icons.check_circle;
      case 'Pending':
        return Icons.hourglass_top;
      case 'Disapproved':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusIconColor(String status) {
    switch (status) {
      case 'Borrowed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Disapproved':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? dropdownValue;
    if (loanStatus == "Borrowed") {
      dropdownValue = "Approve";
    } else if (loanStatus == "Disapproved") {
      dropdownValue = "Disapprove";
    } else {
      dropdownValue = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 1, child: Text(id, textAlign: TextAlign.center)),
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
                width: 35,
                height: 35,
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
              loanStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getStatusColor(loanStatus),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 100,
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(loanStatus),
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    hint: Icon(
                      _getStatusIcon(loanStatus),
                      color: _getStatusIconColor(loanStatus),
                      size: 18,
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: <String>['Approve', 'Disapprove'].map((value) {
                      Color itemColor = value == 'Approve'
                          ? Colors.green
                          : Colors.red;
                      IconData itemIcon = value == 'Approve'
                          ? Icons.check_circle
                          : Icons.cancel;
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(itemIcon, color: itemColor, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: itemColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) onStatusChanged(id, newValue);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
