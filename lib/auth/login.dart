import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saas/qr_scan.dart';
import 'register.dart';

import '../gym_owner.dart';
import '../gym_user.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _key = GlobalKey<FormState>();
  final _mailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _mailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

Future<void> _handleLogin() async {
  if (!_key.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;


    UserCredential credential;
    try {
      credential = await auth.signInWithEmailAndPassword(
        email: _mailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Login failed";
      if (e.code == 'user-not-found') msg = "No account found with this email.";
      if (e.code == 'wrong-password') msg = "Incorrect password.";
      if (e.code == 'invalid-email') msg = "The email address is badly formatted.";
      throw msg;
    }

    User? user = credential.user;
    if (user == null) throw 'Authentication failed.';


    await user.reload();
    user = auth.currentUser;
    if (!user!.emailVerified) {
      await auth.signOut();
      throw 'Please verify your email address before logging in.';
    }

    DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await auth.signOut();
      throw 'User profile not found in database.';
    }

    if (userDoc['isVerified'] == false) {
      await firestore.collection('users').doc(user.uid).update({'isVerified': true});
    }

    String role = userDoc['role'];
    String userGymId = userDoc['gymId'];

    DocumentSnapshot gymDoc = await firestore.collection('gyms').doc(userGymId).get();
    
    if (!gymDoc.exists) {
      await auth.signOut();
      throw 'Your assigned gym was not found.';
    }

    String actualGymCode = gymDoc['registrationCode'] ?? "";
    String enteredCode = _codeController.text.trim();

    if (enteredCode != actualGymCode) {
      await auth.signOut(); 
      throw 'INVALID GYM CODE: You do not have access to this facility.';
    }

    
    if (role == 'member') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GymUser()),
        (route) => false,
      );
    } else if (role == 'owner') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GymOwner()),
        (route) => false,
      );
    }

  } catch (e) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
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
                  "WELCOME BACK",
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "Log in to continue your progress.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 50),
                
                
                Form(
                  key: _key,
                  child: Column(
                    children: [
                      
                      
                      
                      TextFormField(
                        controller: _mailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.email],
                        decoration: _inputDecoration(
                          label: "Email Address",
                          hint: "",
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) => !v!.contains("@") ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 20),
                    
                    
                    
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        style: const TextStyle(color: Colors.white),
                        autofillHints: const [AutofillHints.password],
                        decoration: _inputDecoration(
                          label: "Password",
                          hint: "",
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                              color: Colors.yellowAccent,
                            ),
                            onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter your password" : null,
                      ),
                      const SizedBox(height: 20),
                    
                    
                    
                      TextFormField(
                        controller: _codeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          label: "Gym Code",
                          hint: "Owners leave blank or use Master Code",
                          icon: Icons.pin_drop_outlined,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code, color: Colors.yellowAccent),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const QRScannerPage()),
                              );
                              if (result != null) {
                                setState(() => _codeController.text = result);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    
                    
                    
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text("LOG IN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 25),
                    
                    
                    
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Register())),
                            child: const Text("Register", style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    
                    
                    
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

  InputDecoration _inputDecoration({required String label, required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.yellowAccent),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.yellowAccent),
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.yellowAccent, width: 2)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}