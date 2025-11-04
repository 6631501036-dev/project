import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'SportEquipment.dart';
import 'dart:async'; // 👈 1. เพิ่ม import 'dart:async' เพื่อใช้ Timeout

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    // 👈 2. เปลี่ยน URL ให้ตรงกับ Server.js
    // ใช้ 10.0.2.2 สำหรับ Android Emulator เพื่อเชื่อมต่อกับ localhost ของคอมพิวเตอร์
    final url = Uri.parse("http://192.168.184.1:4400/login");

    // 👈 3. ครอบโค้ดทั้งหมดด้วย try...catch เพื่อดักจับ Error
    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": _usernameController.text,
              "password": _passwordController.text,
            }),
            // 👈 (แนะนำ) เพิ่ม timeout กันการค้าง
          )
          .timeout(const Duration(seconds: 5));

      // 👈 (แนะนำ) ตรวจสอบว่า widget ยังอยู่ก่อนเรียก setState/Navigator
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          // ✅ สำเร็จ: แสดง "ok" ตามที่ขอ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ok")), // 👈 4. เปลี่ยนข้อความ
          );

          // ✅ เปลี่ยนหน้าไป HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Sportequipment()),
          );
        } else {
          // ❌ ล้มเหลว (จาก Server): แสดง Error Message จาก Server
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${data['message']}"),
            ), // 👈 5. แสดง error จาก server
          );
        }
      } else {
        // ❌ ล้มเหลว (Http Error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // ❌ ล้มเหลว (Network/Timeout/อื่นๆ): แสดง Error ที่เกิดขึ้น
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection Error: ${e.toString()}"),
        ), // 👈 6. แสดง error ที่ดักจับได้
      );
    } finally {
      // 👈 7. ไม่ว่าจะสำเร็จหรือล้มเหลว ต้องหยุด Loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _register() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigate to Register Page')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9ECFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Log in",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Username
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: 'Enter your username',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Enter your password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Log in"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB3DEFF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Register"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
