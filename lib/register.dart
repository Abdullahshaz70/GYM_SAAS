import 'package:flutter/material.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _key = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _qrController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;

  @override
  void dispose() {
    _nameController.dispose();
    _mailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _qrController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.yellowAccent),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "JOIN THE CLUB",
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "Start your fitness journey today.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _key,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: _inputDecoration(
                          label: "Full Name",
                          hint: "",
                          icon: Icons.person_outline,
                        ),
                        validator: (v) => v!.isEmpty ? "Enter your name" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: "Email Address",
                          hint: "",
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) =>
                            !v!.contains("@") ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: _inputDecoration(
                          label: "Contact Number",
                          hint: "+923001234567",
                          icon: Icons.phone_android,
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return "Enter contact number";
                          if (!RegExp(r'^\+92\s?3\d{2}\s?\d{7}$')
                              .hasMatch(v)) return "Format: +92 3XXXXXXXXX";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: _inputDecoration(
                          label: "Password",
                          hint: "",
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.yellowAccent,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _isPasswordObscured = !_isPasswordObscured);
                            },
                          ),
                        ),
                        validator: (v) =>
                            v!.length < 6 ? "Minimum 6 characters" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _isConfirmObscured,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.password],
                        decoration: _inputDecoration(
                          label: "Confirm Password",
                          hint: "",
                          icon: Icons.lock_reset,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.yellowAccent,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _isConfirmObscured = !_isConfirmObscured);
                            },
                          ),
                        ),
                        validator: (v) => v != _passwordController.text
                            ? "Passwords do not match"
                            : null,
                      ),
                      const SizedBox(height: 40),
                    

                    Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: TextFormField(
        controller: _qrController,
        style: const TextStyle(color: Colors.white),
        readOnly: true,
        decoration: _inputDecoration(
          label: "Gym QR String",
          hint: "Scan to fill",
          icon: Icons.vpn_key_outlined,
        ),
        validator: (v) => v!.isEmpty ? "Scan QR first" : null,
      ),
    ),
    const SizedBox(width: 12),
    GestureDetector(
      onTap: () async {
        final String? result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QRScannerPage()),
        );
        if (result != null) {
          setState(() {
            _qrController.text = result;
          });
        }
      },
      child: Container(
        height: 58,
        width: 58,
        decoration: BoxDecoration(
          color: Colors.yellowAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 30),
      ),
    ),
  ],
),
                    
                    
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_key.currentState!.validate()) {}
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                            shadowColor: Colors.yellowAccent.withOpacity(0.4),
                          ),
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    
                    
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ",
                              style: TextStyle(color: Colors.white70)),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushAndRemoveUntil<dynamic>(
                                context,
                                MaterialPageRoute<dynamic>(
                                  builder: (BuildContext context) => Login(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold,
                                
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                    
                    
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }














    InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.yellowAccent),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.yellowAccent),
      hintStyle: const TextStyle(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.yellowAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }

}