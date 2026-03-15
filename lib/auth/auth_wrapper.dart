// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'login.dart';
// import '../user/gym_user.dart';
// import '../owner/gym_owner.dart';

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const AuthSplashScreen(); // ← animated splash
//         }

//         if (!snapshot.hasData) {
//           return const Login();
//         }

//         return FutureBuilder<DocumentSnapshot>(
//           future: FirebaseFirestore.instance
//               .collection('users')
//               .doc(snapshot.data!.uid)
//               .get(),
//           builder: (context, userSnapshot) {
//             if (userSnapshot.connectionState == ConnectionState.waiting) {
//               return const AuthSplashScreen(); // ← also here
//             }

//             if (userSnapshot.hasData && userSnapshot.data!.exists) {
//               String role = userSnapshot.data!['role'];
//               if (role == 'owner') return const GymOwner();
//               else return const GymUser();
//             }

//             return const Login();
//           },
//         );
//       },
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  Animated Splash Screen
// // ─────────────────────────────────────────────────────────────
// class AuthSplashScreen extends StatefulWidget {
//   const AuthSplashScreen({super.key});

//   @override
//   State<AuthSplashScreen> createState() => _AuthSplashScreenState();
// }

// class _AuthSplashScreenState extends State<AuthSplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnim;
//   late Animation<double> _fadeAnim;
//   late Animation<double> _taglineFadeAnim;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     );

//     // Logo: scale from 0.6 → 1.0
//     _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
//       ),
//     );

//     // Logo: fade 0 → 1
//     _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
//       ),
//     );

//     // Tagline fades in after logo settles
//     _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
//       ),
//     );

//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: _controller,
//           builder: (context, _) {
//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ── Animated logo box ──────────────────────────
//                 FadeTransition(
//                   opacity: _fadeAnim,
//                   child: ScaleTransition(
//                     scale: _scaleAnim,
//                     child: _LogoBadge(),
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // ── App name ───────────────────────────────────
//                 FadeTransition(
//                   opacity: _fadeAnim,
//                   child: ScaleTransition(
//                     scale: _scaleAnim,
//                     child: const Text(
//                       "PRO TRACKER",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 4,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 // ── Tagline (delayed fade) ─────────────────────
//                 Opacity(
//                   opacity: _taglineFadeAnim.value,
//                   child: const Text(
//                     "TRAIN. TRACK. DOMINATE.",
//                     style: TextStyle(
//                       color: Colors.yellowAccent,
//                       fontSize: 11,
//                       letterSpacing: 2.5,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  Logo Badge  — swap this out when you have a real logo
// // ─────────────────────────────────────────────────────────────
// class _LogoBadge extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 110,
//       height: 110,
//       decoration: BoxDecoration(
//         color: Colors.yellowAccent,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.yellowAccent.withOpacity(0.35),
//             blurRadius: 40,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: const Center(
//         child: Text(
//           "GT",                          // ← change to your initials / logo
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 46,
//             fontWeight: FontWeight.w900,
//             letterSpacing: -1,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import '../user/gym_user.dart';
import '../owner/gym_owner.dart';
import '../staff/gym_staff.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthSplashScreen(); // ← animated splash
        }

        if (!snapshot.hasData) {
          return const Login();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const AuthSplashScreen(); // ← also here
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              String role = userSnapshot.data!['role'];
              if (role == 'owner') return const GymOwner();
              if (role == 'staff') return const GymStaff();
              return const GymUser();
            }

            return const Login();
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Animated Splash Screen
// ─────────────────────────────────────────────────────────────
class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _taglineFadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo: scale from 0.6 → 1.0
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Logo: fade 0 → 1
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Tagline fades in after logo settles
    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated logo box ──────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: _LogoBadge(),
                  ),
                ),

                const SizedBox(height: 24),

                // ── App name ───────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: const Text(
                      "PRO TRACKER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Tagline (delayed fade) ─────────────────────
                Opacity(
                  opacity: _taglineFadeAnim.value,
                  child: const Text(
                    "TRAIN. TRACK. DOMINATE.",
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 11,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
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
}

// ─────────────────────────────────────────────────────────────
//  Logo Badge  — swap this out when you have a real logo
// ─────────────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.yellowAccent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.yellowAccent.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "GT",                          // ← change to your initials / logo
          style: TextStyle(
            color: Colors.black,
            fontSize: 46,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}