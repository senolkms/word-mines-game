import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String mesaj = '';

  Future<void> login() async {
  final response = await ApiService().login(
    usernameController.text.trim(),
    passwordController.text.trim(),
  );

  setState(() {
    mesaj = response.toString();
  });

  if (response['token'] != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', response['token']);

    Navigator.pushReplacementNamed(context, '/dashboard');
  }
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Klavye açıldığında taşmayı engeller
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Arka plan (görsel orijinal oranda korunur, ekran taşması engellenir)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),

                // Giriş içeriği
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 200), // Logo ile kutular arasında boşluk
                        _buildTextField(
                          icon: Icons.person,
                          hint: 'Kullanıcı Adı',
                          controller: usernameController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          icon: Icons.lock,
                          hint: 'Şifre',
                          controller: passwordController,
                          obscure: true,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[900],
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Giriş Yap', style: TextStyle(fontSize: 18,color: Colors.white)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text('Hesabınız yok mu? Kayıt Ol'),
                        ),
                        if (mesaj.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(mesaj, style: const TextStyle(color: Colors.red)),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}