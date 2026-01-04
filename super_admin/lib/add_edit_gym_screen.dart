// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class AddEditGymScreen extends StatefulWidget {
//   final String? gymId; // null = Add, not null = Edit
//   const AddEditGymScreen({super.key, this.gymId});

//   @override
//   State<AddEditGymScreen> createState() => _AddEditGymScreenState();
// }

// class _AddEditGymScreenState extends State<AddEditGymScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // Gym controllers
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController locationController = TextEditingController();
//   final TextEditingController feeController = TextEditingController();
//   final TextEditingController registrationController = TextEditingController();

//   // Owner controllers
//   final TextEditingController ownerNameController = TextEditingController();
//   final TextEditingController ownerEmailController = TextEditingController();
//   final TextEditingController ownerContactController = TextEditingController();
//   final TextEditingController ownerPasswordController = TextEditingController();

//   bool isSaaSActive = true;
//   bool isLoading = false;

//   String ownerUid = "";

//   @override
//   void initState() {
//     super.initState();
//     if (widget.gymId != null) {
//       _loadGymData();
//     }
//   }

//   Future<void> _loadGymData() async {
//     final doc = await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).get();
//     if (!doc.exists) return;
//     final data = doc.data() ?? {};

//     setState(() {
//       nameController.text = data['gymName'] ?? '';
//       locationController.text = data['location'] ?? '';
//       feeController.text = (data['defaultFee'] ?? 0).toString();
//       registrationController.text = data['registrationCode'] ?? '';
//       isSaaSActive = data['isSaaSActive'] ?? true;
//       ownerUid = data['ownerUid'] ?? "";
//     });

//     // Load owner details if gym has an owner
//     if (ownerUid.isNotEmpty) {
//       final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
//       if (ownerDoc.exists) {
//         final ownerData = ownerDoc.data() ?? {};
//         ownerNameController.text = ownerData['name'] ?? '';
//         ownerEmailController.text = ownerData['email'] ?? '';
//         ownerContactController.text = ownerData['contactNumber'] ?? '';
//       }
//     }
//   }

//   Future<void> _saveGym() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => isLoading = true);

//     try {
//       // If adding a new gym, first create the owner user
//       if (widget.gymId == null) {
//         // Create owner in Firebase Auth
//         final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: ownerEmailController.text.trim(),
//           password: ownerPasswordController.text.trim(),
//         );

//         ownerUid = userCred.user!.uid;

//         // Save owner in Firestore
//         await FirebaseFirestore.instance.collection('users').doc(ownerUid).set({
//           'name': ownerNameController.text.trim(),
//           'email': ownerEmailController.text.trim(),
//           'role': 'owner',
//           'gymId': '', // will update after gym creation
//           'isVerified': true,
//           'status': 'active',
//           'contactNumber': ownerContactController.text.trim(),
//           'createdAt': Timestamp.now(),
//         });

//         // Create the gym
//         final gymRef = await FirebaseFirestore.instance.collection('gyms').add({
//           'gymName': nameController.text.trim(),
//           'location': locationController.text.trim(),
//           'defaultFee': num.tryParse(feeController.text) ?? 0,
//           'registrationCode': registrationController.text.isEmpty
//               ? DateTime.now().millisecondsSinceEpoch.toString()
//               : registrationController.text.trim(),
//           'status': 'active',
//           'isSaaSActive': isSaaSActive,
//           'createdAt': Timestamp.now(),
//           'ownerUid': ownerUid,
//         });

//         // Update owner's gymId
//         await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
//           'gymId': gymRef.id,
//         });
//       } else {
//         // Editing existing gym
//         await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).update({
//           'gymName': nameController.text.trim(),
//           'location': locationController.text.trim(),
//           'defaultFee': num.tryParse(feeController.text) ?? 0,
//           'registrationCode': registrationController.text.isEmpty
//               ? DateTime.now().millisecondsSinceEpoch.toString()
//               : registrationController.text.trim(),
//           'isSaaSActive': isSaaSActive,
//         });

//         // Update owner info if exists
//         if (ownerUid.isNotEmpty) {
//           await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
//             'name': ownerNameController.text.trim(),
//             'email': ownerEmailController.text.trim(),
//             'contactNumber': ownerContactController.text.trim(),
//           });
//         }
//       }

//       Navigator.pop(context);
//     } catch (e) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.gymId == null ? "Add Gym" : "Edit Gym")),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     const Text("GYM DETAILS", style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 10),
//                     TextFormField(
//                       controller: nameController,
//                       decoration: const InputDecoration(labelText: "Gym Name"),
//                       validator: (val) => val == null || val.isEmpty ? "Enter gym name" : null,
//                     ),
//                     TextFormField(
//                       controller: locationController,
//                       decoration: const InputDecoration(labelText: "Location"),
//                       validator: (val) => val == null || val.isEmpty ? "Enter location" : null,
//                     ),
//                     TextFormField(
//                       controller: feeController,
//                       decoration: const InputDecoration(labelText: "Default Fee"),
//                       keyboardType: TextInputType.number,
//                       validator: (val) => val == null || val.isEmpty ? "Enter fee" : null,
//                     ),

//                     TextFormField(
//   controller: registrationController,
//   decoration: const InputDecoration(labelText: "Registration Code"),
//   validator: (val) => val == null || val.isEmpty ? "Enter registration code" : null,
// ),


//                     const SizedBox(height: 10),
//                     SwitchListTile(
//                       title: const Text("SaaS Active"),
//                       value: isSaaSActive,
//                       onChanged: (val) => setState(() => isSaaSActive = val),
//                     ),
//                     const Divider(height: 30, thickness: 1, color: Colors.white24),
//                     const Text("OWNER DETAILS", style: TextStyle(fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 10),
//                     TextFormField(
//                       controller: ownerNameController,
//                       decoration: const InputDecoration(labelText: "Owner Name"),
//                       validator: (val) => val == null || val.isEmpty ? "Enter owner name" : null,
//                     ),
//                     TextFormField(
//                       controller: ownerEmailController,
//                       decoration: const InputDecoration(labelText: "Owner Email"),
//                       validator: (val) => val == null || val.isEmpty ? "Enter owner email" : null,
//                     ),
//                     TextFormField(
//                       controller: ownerContactController,
//                       decoration: const InputDecoration(labelText: "Owner Contact"),
//                       validator: (val) => val == null || val.isEmpty ? "Enter contact number" : null,
//                     ),
//                     if (widget.gymId == null) // only for new gym
//                       TextFormField(
//                         controller: ownerPasswordController,
//                         decoration: const InputDecoration(labelText: "Owner Password"),
//                         obscureText: true,
//                         validator: (val) => val == null || val.isEmpty ? "Enter password" : null,
//                       ),
//                     const SizedBox(height: 30),
//                     ElevatedButton(
//                       onPressed: _saveGym,
//                       child: Text(widget.gymId == null ? "Create Gym & Owner" : "Update Gym & Owner"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditGymScreen extends StatefulWidget {
  final String? gymId; // null = Add, not null = Edit
  const AddEditGymScreen({super.key, this.gymId});

  @override
  State<AddEditGymScreen> createState() => _AddEditGymScreenState();
}

class _AddEditGymScreenState extends State<AddEditGymScreen> {
  final _formKey = GlobalKey<FormState>();

  // Gym controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController registrationController = TextEditingController();
  bool isSaaSActive = true;

  // Owner controllers
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerEmailController = TextEditingController();
  final TextEditingController ownerPasswordController = TextEditingController();
  final TextEditingController ownerContactController = TextEditingController();

  String ownerUid = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.gymId != null) {
      _loadGymData();
    }
  }

  // Load gym + owner data if editing
  Future<void> _loadGymData() async {
    final doc = await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};

    setState(() {
      nameController.text = data['gymName'] ?? '';
      locationController.text = data['location'] ?? '';
      feeController.text = (data['defaultFee'] ?? 0).toString();
      registrationController.text = data['registrationCode'] ?? '';
      isSaaSActive = data['isSaaSActive'] ?? true;
      ownerUid = data['ownerUid'] ?? "";
    });

    // Load owner details if gym has an owner
    if (ownerUid.isNotEmpty) {
      final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data() ?? {};
        ownerNameController.text = ownerData['name'] ?? '';
        ownerEmailController.text = ownerData['email'] ?? '';
        ownerContactController.text = ownerData['contactNumber'] ?? '';
      }
    }
  }

  // Save gym + owner
  Future<void> _saveGym() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // ADD NEW GYM
      if (widget.gymId == null) {
        // 1️⃣ Create owner in Firebase Auth
        final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: ownerEmailController.text.trim(),
          password: ownerPasswordController.text.trim(),
        );
        ownerUid = userCred.user!.uid;

        // 2️⃣ Save owner in Firestore
        await FirebaseFirestore.instance.collection('users').doc(ownerUid).set({
          'name': ownerNameController.text.trim(),
          'email': ownerEmailController.text.trim(),
          'role': 'owner',
          'gymId': '', // will update after gym creation
          'isVerified': true,
          'status': 'active',
          'contactNumber': ownerContactController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        // 3️⃣ Create the gym
        final gymRef = await FirebaseFirestore.instance.collection('gyms').add({
          'gymName': nameController.text.trim(),
          'location': locationController.text.trim(),
          'defaultFee': num.tryParse(feeController.text) ?? 0,
          'registrationCode': registrationController.text.trim(),
          'status': 'active',
          'isSaaSActive': isSaaSActive,
          'createdAt': Timestamp.now(),
          'ownerUid': ownerUid,
        });

        // 4️⃣ Update owner's gymId
        await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
          'gymId': gymRef.id,
        });
      } 
      // EDIT EXISTING GYM
      else {
        await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).update({
          'gymName': nameController.text.trim(),
          'location': locationController.text.trim(),
          'defaultFee': num.tryParse(feeController.text) ?? 0,
          'registrationCode': registrationController.text.trim(),
          'isSaaSActive': isSaaSActive,
        });

        // Update owner info if exists
        if (ownerUid.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
            'name': ownerNameController.text.trim(),
            'email': ownerEmailController.text.trim(),
            'contactNumber': ownerContactController.text.trim(),
          });
        }
      }

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gymId == null ? "Add Gym" : "Edit Gym")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // GYM FIELDS
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Gym Name"),
                      validator: (val) => val == null || val.isEmpty ? "Enter gym name" : null,
                    ),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                      validator: (val) => val == null || val.isEmpty ? "Enter location" : null,
                    ),
                    TextFormField(
                      controller: feeController,
                      decoration: const InputDecoration(labelText: "Default Fee"),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? "Enter fee" : null,
                    ),
                    TextFormField(
                      controller: registrationController,
                      decoration: const InputDecoration(labelText: "Registration Code"),
                      validator: (val) => val == null || val.isEmpty ? "Enter registration code" : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SaaS Active", style: TextStyle(fontSize: 16)),
                        Switch(
                          value: isSaaSActive,
                          onChanged: (val) => setState(() => isSaaSActive = val),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1, color: Colors.white24),
                    const SizedBox(height: 10),

                    // OWNER FIELDS
                    TextFormField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(labelText: "Owner Name"),
                      validator: (val) => val == null || val.isEmpty ? "Enter owner name" : null,
                    ),
                    TextFormField(
                      controller: ownerEmailController,
                      decoration: const InputDecoration(labelText: "Owner Email"),
                      validator: (val) => val == null || val.isEmpty ? "Enter owner email" : null,
                    ),
                    if (widget.gymId == null) // only when adding new owner
                      TextFormField(
                        controller: ownerPasswordController,
                        decoration: const InputDecoration(labelText: "Owner Password"),
                        obscureText: true,
                        validator: (val) => val == null || val.isEmpty ? "Enter password" : null,
                      ),
                    TextFormField(
                      controller: ownerContactController,
                      decoration: const InputDecoration(labelText: "Owner Contact"),
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _saveGym,
                      child: Text(widget.gymId == null ? "Create Gym" : "Update Gym"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
