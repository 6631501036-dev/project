import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 1. Data Model
// -----------------------------------------------------------------------------
class HistoryRecord {
  final String id, item, borrowDate, returnDate, student, lender, staff, status;

  const HistoryRecord({
    required this.id,
    required this.item,
    required this.borrowDate,
    required this.returnDate,
    required this.student,
    required this.lender,
    required this.staff,
    required this.status,
  });
}

// -----------------------------------------------------------------------------
// 2. Staff History Screen (The main view)
// -----------------------------------------------------------------------------
class StaffHistory extends StatefulWidget {
  const StaffHistory({super.key});

  @override
  State<StaffHistory> createState() => _StaffHistoryState();
}

class _StaffHistoryState extends State<StaffHistory> {
  // Static Data (will eventually come from a database)
  final List<HistoryRecord> _records = const [
    HistoryRecord(
      id: "1",
      item: "balls",
      borrowDate: "10/11/2025",
      returnDate: "12/11/2025",
      student: "student_1",
      lender: "lender_1",
      staff: "staff_1",
      status: "Approved",
    ),
    HistoryRecord(
      id: "2",
      item: "Basketball",
      borrowDate: "10/11/2025",
      returnDate: "12/11/2025",
      student: "student_2",
      lender: "lender_2",
      staff: "-",
      status: "Disapproved",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header and Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              color: Colors.lightBlue[100],
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 30),
                      color: Colors.black,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Profile Icon
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.person, size: 50, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  // Staff Name
                  const Text(
                    "John Doe (Staff)",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // History Table Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _HistoryTable(records: _records),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Custom History Table Widget
// -----------------------------------------------------------------------------
class _HistoryTable extends StatelessWidget {
  final List<HistoryRecord> records;

  const _HistoryTable({required this.records});

  @override
  Widget build(BuildContext context) {
    // The table is wrapped in a Container to give it the rounded white card look
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const _HistoryRow(
              isHeader: true,
              id: "ID",
              item: "Item",
              borrowDate: "Borrow date",
              returnDate: "Return date",
              student: "Student",
              lender: "Lender",
              staff: "Staff",
              status: "Status",
            ),
          ),

          // Table Rows
          ...records.map((r) {
            return Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Colors.black),
                _HistoryRow(
                  id: r.id,
                  item: r.item,
                  borrowDate: r.borrowDate,
                  returnDate: r.returnDate,
                  student: r.student,
                  lender: r.lender,
                  staff: r.staff,
                  status: r.status,
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Custom Table Row Widget
// -----------------------------------------------------------------------------
class _HistoryRow extends StatelessWidget {
  final String id, item, borrowDate, returnDate, student, lender, staff, status;
  final bool isHeader;

  const _HistoryRow({
    required this.id,
    required this.item,
    required this.borrowDate,
    required this.returnDate,
    required this.student,
    required this.lender,
    required this.staff,
    required this.status,
    this.isHeader = false,
  });

  // ✅ Function to return color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'disapproved':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 11 : 9,
      color: Colors.black,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID
          Expanded(
            flex: 1,
            child: Text(id, style: baseStyle, textAlign: TextAlign.center),
          ),
          // Item
          Expanded(
            flex: 3,
            child: Text(item, style: baseStyle, textAlign: TextAlign.center),
          ),
          // Borrow Date
          Expanded(
            flex: 3,
            child: Text(
              borrowDate,
              style: baseStyle,
              textAlign: TextAlign.center,
            ),
          ),
          // Return Date
          Expanded(
            flex: 3,
            child: Text(
              returnDate,
              style: baseStyle,
              textAlign: TextAlign.center,
            ),
          ),
          // Student
          Expanded(
            flex: 3,
            child: Text(student, style: baseStyle, textAlign: TextAlign.center),
          ),
          // Lender
          Expanded(
            flex: 3,
            child: Text(lender, style: baseStyle, textAlign: TextAlign.center),
          ),
          // Staff
          Expanded(
            flex: 2,
            child: Text(staff, style: baseStyle, textAlign: TextAlign.center),
          ),

          // ✅ Status (color depends on value)
          Expanded(
            flex: 3,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
