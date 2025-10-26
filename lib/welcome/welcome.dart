import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8), // ฟ้าอ่อน
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ข้อความต้อนรับ
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Sport asset borrowed",
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 30),

              // รูปภาพวงกลม
              ClipOval(
                child: Image.asset(
                  'assets/image/landing.jpg', // ใช้รูปที่แนบไว้ เช่นเปลี่ยนชื่อไฟล์นี้
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 50),

              // ปุ่ม Sign in
              ElevatedButton(
                onPressed: () {
                  // ไปหน้า sign in
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Sign in",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
