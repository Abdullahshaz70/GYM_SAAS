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
//   final TextEditingController planController = TextEditingController();

//   // Owner controllers
//   final TextEditingController ownerNameController = TextEditingController();
//   final TextEditingController ownerEmailController = TextEditingController();
//   final TextEditingController ownerContactController = TextEditingController();
//   final TextEditingController ownerPasswordController = TextEditingController();

//   bool isSaaSActive = true;
//   bool isLoading = false;
//   String ownerUid = "";

//   // Merchant Credentials
//   List<MerchantCredential> merchantList = [];

//   @override
//   void initState() {
//     super.initState();
//     if (widget.gymId != null) {
//       _loadGymData();
//       _loadMerchantData();
//     } else {
//       // Start with one empty merchant slot for new gyms
//       merchantList.add(MerchantCredential());
//     }
//   }

//   Future<void> _loadGymData() async {
//     setState(() => isLoading = true);
//     final doc = await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).get();
//     if (!doc.exists) return;
//     final data = doc.data() ?? {};

//     setState(() {
//       nameController.text = data['gymName'] ?? '';
//       locationController.text = data['location'] ?? '';
//       feeController.text = (data['defaultFee'] ?? 0).toString();
//       registrationController.text = data['registrationCode'] ?? '';
//       planController.text = data['plan'] ?? '';
//       isSaaSActive = data['isSaaSActive'] ?? true;
//       ownerUid = data['ownerUid'] ?? "";
//     });

//     if (ownerUid.isNotEmpty) {
//       final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
//       if (ownerDoc.exists) {
//         final ownerData = ownerDoc.data() ?? {};
//         setState(() {
//           ownerNameController.text = ownerData['name'] ?? '';
//           ownerEmailController.text = ownerData['email'] ?? '';
//           ownerContactController.text = ownerData['contactNumber'] ?? '';
//         });
//       }
//     }

//     setState(() => isLoading = false);
//   }

//   Future<void> _loadMerchantData() async {
//     if (widget.gymId == null) return;

//     final snapshot = await FirebaseFirestore.instance
//         .collection('gyms')
//         .doc(widget.gymId)
//         .collection('merchantCredentials')
//         .get();

//     setState(() {
//       merchantList = snapshot.docs
//           .map((doc) => MerchantCredential.fromMap(doc.data(), doc.id))
//           .toList();
//       if (merchantList.isEmpty) {
//         merchantList.add(MerchantCredential()); // at least one empty slot
//       }
//     });
//   }

//   Future<void> _saveGym() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => isLoading = true);

//     try {
//       String gymId = widget.gymId ?? '';

//       if (widget.gymId == null) {
//         // CREATE owner first
//         final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: ownerEmailController.text.trim(),
//           password: ownerPasswordController.text.trim(),
//         );

//         ownerUid = userCred.user!.uid;

//         await FirebaseFirestore.instance.collection('users').doc(ownerUid).set({
//           'name': ownerNameController.text.trim(),
//           'email': ownerEmailController.text.trim(),
//           'role': 'owner',
//           'gymId': '',
//           'isVerified': true,
//           'status': 'active',
//           'contactNumber': ownerContactController.text.trim(),
//           'createdAt': Timestamp.now(),
//         });

//         final gymRef = await FirebaseFirestore.instance.collection('gyms').add({
//           'gymName': nameController.text.trim(),
//           'location': locationController.text.trim(),
//           'defaultFee': num.tryParse(feeController.text) ?? 0,
//           'registrationCode': registrationController.text.isEmpty
//               ? DateTime.now().millisecondsSinceEpoch.toString()
//               : registrationController.text.trim(),
//           'plan': planController.text.trim(),
//           'status': 'active',
//           'isSaaSActive': isSaaSActive,
//           'createdAt': Timestamp.now(),
//           'ownerUid': ownerUid,
//         });

//         gymId = gymRef.id;

//         await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
//           'gymId': gymId,
//         });
//       } else {
//         // UPDATE existing gym
//         await FirebaseFirestore.instance.collection('gyms').doc(gymId).update({
//           'gymName': nameController.text.trim(),
//           'location': locationController.text.trim(),
//           'defaultFee': num.tryParse(feeController.text) ?? 0,
//           'registrationCode': registrationController.text.trim(),
//           'plan': planController.text.trim(),
//           'isSaaSActive': isSaaSActive,
//         });

//         if (ownerUid.isNotEmpty) {
//           await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
//             'name': ownerNameController.text.trim(),
//             'email': ownerEmailController.text.trim(),
//             'contactNumber': ownerContactController.text.trim(),
//           });
//         }
//       }

//       // SAVE Merchant Credentials
//       final merchantCol = FirebaseFirestore.instance
//           .collection('gyms')
//           .doc(gymId)
//           .collection('merchantCredentials');

//       for (var merchant in merchantList) {
//         if (merchant.gateway.isEmpty) continue;

//         if (merchant.id.isEmpty) {
//           // new
//           await merchantCol.add({
//             'gateway': merchant.gateway,
//             'storeId': merchant.storeId,
//             'hashKey': merchant.hashKey,
//             'accountNumber': merchant.accountNumber,
//             'environment': merchant.environment,
//             'createdAt': Timestamp.now(),
//             'updatedAt': Timestamp.now(),
//           });
//         } else {
//           // update
//           await merchantCol.doc(merchant.id).update({
//             'gateway': merchant.gateway,
//             'storeId': merchant.storeId,
//             'hashKey': merchant.hashKey,
//             'accountNumber': merchant.accountNumber,
//             'environment': merchant.environment,
//             'updatedAt': Timestamp.now(),
//           });
//         }
//       }

//       if (mounted) Navigator.pop(context);
//     } catch (e) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   Widget _buildMerchantForm() {
//     return Column(
//       children: [
//         ...merchantList.asMap().entries.map((entry) {
//           final index = entry.key;
//           final merchant = entry.value;

//           return Card(
//             color: Colors.white10,
//             margin: const EdgeInsets.only(top: 10),
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(child: Text("Merchant ${index + 1}", style: const TextStyle(color: Colors.white))),
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.redAccent),
//                        onPressed: () async {
//   final merchantId = merchant.id;

//   // 1. If it exists in Firestore, delete it there first
//   if (widget.gymId != null && merchantId.isNotEmpty) {
//     bool confirm = await _showDeleteConfirmation();
//     if (!confirm) return;

//     setState(() => isLoading = true);
//     try {
//       await FirebaseFirestore.instance
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('merchantCredentials')
//           .doc(merchantId)
//           .delete();
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Merchant deleted from database"))
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error deleting: $e"))
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   // 2. Remove from the local UI list
//   setState(() => merchantList.removeAt(index));
// },
//                       )
//                     ],
//                   ),
//                   TextFormField(
//                     initialValue: merchant.gateway,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: _fieldStyle("Gateway (e.g., easypaisa)", Icons.payment),
//                     onChanged: (val) => merchant.gateway = val,
//                   ),
//                   TextFormField(
//                     initialValue: merchant.storeId,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: _fieldStyle("Store ID", Icons.store),
//                     onChanged: (val) => merchant.storeId = val,
//                   ),
//                   TextFormField(
//                     initialValue: merchant.hashKey,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: _fieldStyle("Hash Key (Encrypted)", Icons.lock),
//                     onChanged: (val) => merchant.hashKey = val,
//                   ),
//                   TextFormField(
//                     initialValue: merchant.accountNumber,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: _fieldStyle("Account Number", Icons.account_balance),
//                     onChanged: (val) => merchant.accountNumber = val,
//                   ),
//                   TextFormField(
//                     initialValue: merchant.environment,
//                     style: const TextStyle(color: Colors.white),
//                     decoration: _fieldStyle("Environment (sandbox|production)", Icons.cloud),
//                     onChanged: (val) => merchant.environment = val,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//         const SizedBox(height: 10),
//         ElevatedButton.icon(
//           onPressed: () {
//             setState(() => merchantList.add(MerchantCredential()));
//           },
//           icon: const Icon(Icons.add),
//           label: const Text("Add Merchant"),
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent, foregroundColor: Colors.black),
//         ),
//       ],
//     );
//   }


//   InputDecoration _fieldStyle(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: Icon(icon, color: Colors.yellowAccent, size: 20),
//       labelStyle: const TextStyle(color: Colors.white60),
//       enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
//       focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellowAccent)),
//     );
//   }


// Future<bool> _showDeleteConfirmation() async {
//   return await showDialog(
//     context: context,
//     builder: (ctx) => AlertDialog(
//       backgroundColor: const Color(0xFF121212),
//       title: const Text("Delete Merchant?", style: TextStyle(color: Colors.white)),
//       content: const Text("This will permanently remove these credentials.",
//           style: TextStyle(color: Colors.white70)),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(ctx, false),
//           child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
//         ),
//         TextButton(
//           onPressed: () => Navigator.pop(ctx, true),
//           child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
//         ),
//       ],
//     ),
//   ) ?? false;
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F0F0F),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(widget.gymId == null ? "ADD GYM" : "EDIT GYM", style: const TextStyle(letterSpacing: 2)),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.yellowAccent))
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     _buildSectionHeader("GYM INFORMATION", Icons.store_rounded),
//                     _buildFormCard([
//                       TextFormField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Gym Name", Icons.badge)),
//                       TextFormField(controller: locationController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Location", Icons.location_on)),
//                       TextFormField(controller: feeController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Monthly Fee", Icons.payments), keyboardType: TextInputType.number),
//                       TextFormField(controller: registrationController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Registration Code", Icons.qr_code)),
//                       TextFormField(controller: planController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Plan (Monthly|6 Months|Yearly)", Icons.calendar_month)),
//                       const SizedBox(height: 10),
//                       SwitchListTile(
//                         title: const Text("SaaS Platform Access", style: TextStyle(color: Colors.white, fontSize: 14)),
//                         value: isSaaSActive,
//                         activeColor: Colors.yellowAccent,
//                         onChanged: (val) => setState(() => isSaaSActive = val),
//                       ),
//                     ]),
//                     const SizedBox(height: 30),
//                     _buildSectionHeader("OWNER INFORMATION", Icons.person_add_rounded),
//                     _buildFormCard([
//                       TextFormField(controller: ownerNameController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Owner Full Name", Icons.person)),
//                       TextFormField(controller: ownerEmailController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Email Address", Icons.email)),
//                       TextFormField(controller: ownerContactController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Contact Number", Icons.phone)),
//                       if (widget.gymId == null)
//                         TextFormField(controller: ownerPasswordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Temporary Password", Icons.lock)),
//                     ]),
//                     const SizedBox(height: 30),
//                     _buildSectionHeader("MERCHANT CREDENTIALS", Icons.credit_card),
//                     _buildMerchantForm(),
//                     const SizedBox(height: 40),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 55,
//                       child: ElevatedButton(
//                         onPressed: _saveGym,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.yellowAccent,
//                           foregroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                         ),
//                         child: Text(widget.gymId == null ? "CREATE ACCOUNT" : "UPDATE DETAILS", style: const TextStyle(fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }


//   Widget _buildSectionHeader(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.white24, size: 18),
//         const SizedBox(width: 8),
//         Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
//       ],
//     );
//   }


//     Widget _buildFormCard(List<Widget> children) {
//     return Container(
//       margin: const EdgeInsets.only(top: 15),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withOpacity(0.05)),
//       ),
//       child: Column(children: children),
//     );
//   }


// }

// class MerchantCredential {
//   String id;
//   String gateway;
//   String storeId;
//   String hashKey;
//   String accountNumber;
//   String environment;

//   MerchantCredential({
//     this.id = '',
//     this.gateway = '',
//     this.storeId = '',
//     this.hashKey = '',
//     this.accountNumber = '',
//     this.environment = 'sandbox',
//   });

//   factory MerchantCredential.fromMap(Map<String, dynamic> map, String docId) {
//     return MerchantCredential(
//       id: docId,
//       gateway: map['gateway'] ?? '',
//       storeId: map['storeId'] ?? '',
//       hashKey: map['hashKey'] ?? '',
//       accountNumber: map['accountNumber'] ?? '',
//       environment: map['environment'] ?? 'sandbox',
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
  final TextEditingController planController = TextEditingController();

  // Owner controllers
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerEmailController = TextEditingController();
  final TextEditingController ownerContactController = TextEditingController();
  final TextEditingController ownerPasswordController = TextEditingController();

  bool isSaaSActive = true;
  bool isLoading = false;
  String ownerUid = "";

  // Merchant Credentials
  List<MerchantCredential> merchantList = [];

  @override
  void initState() {
    super.initState();
    if (widget.gymId != null) {
      _loadGymData();
      _loadMerchantData();
    } else {
      // Start with one empty merchant slot for new gyms
      merchantList.add(MerchantCredential());
    }
  }

  Future<void> _loadGymData() async {
    setState(() => isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};

    setState(() {
      nameController.text = data['gymName'] ?? '';
      locationController.text = data['location'] ?? '';
      feeController.text = (data['defaultFee'] ?? 0).toString();
      registrationController.text = data['registrationCode'] ?? '';
      planController.text = data['plan'] ?? '';
      isSaaSActive = data['isSaaSActive'] ?? true;
      ownerUid = data['ownerUid'] ?? "";
    });

    if (ownerUid.isNotEmpty) {
      final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data() ?? {};
        setState(() {
          ownerNameController.text = ownerData['name'] ?? '';
          ownerEmailController.text = ownerData['email'] ?? '';
          ownerContactController.text = ownerData['contactNumber'] ?? '';
        });
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadMerchantData() async {
    if (widget.gymId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('merchantCredentials')
        .get();

    setState(() {
      merchantList = snapshot.docs
          .map((doc) => MerchantCredential.fromMap(doc.data(), doc.id))
          .toList();
      if (merchantList.isEmpty) {
        merchantList.add(MerchantCredential()); // at least one empty slot
      }
    });
  }

  Future<void> _saveGym() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String gymId = widget.gymId ?? '';

      if (widget.gymId == null) {
        // CREATE owner first
        final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: ownerEmailController.text.trim(),
          password: ownerPasswordController.text.trim(),
        );

        ownerUid = userCred.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(ownerUid).set({
          'name': ownerNameController.text.trim(),
          'email': ownerEmailController.text.trim(),
          'role': 'owner',
          'gymId': '',
          'isVerified': true,
          'status': 'active',
          'contactNumber': ownerContactController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        final gymRef = await FirebaseFirestore.instance.collection('gyms').add({
          'gymName': nameController.text.trim(),
          'location': locationController.text.trim(),
          'defaultFee': num.tryParse(feeController.text) ?? 0,
          'registrationCode': registrationController.text.isEmpty
              ? DateTime.now().millisecondsSinceEpoch.toString()
              : registrationController.text.trim(),
          'plan': planController.text.trim(),
          'status': 'active',
          'isSaaSActive': isSaaSActive,
          'createdAt': Timestamp.now(),
          'ownerUid': ownerUid,
        });

        gymId = gymRef.id;

        await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
          'gymId': gymId,
        });
      } else {
        // UPDATE existing gym
        await FirebaseFirestore.instance.collection('gyms').doc(gymId).update({
          'gymName': nameController.text.trim(),
          'location': locationController.text.trim(),
          'defaultFee': num.tryParse(feeController.text) ?? 0,
          'registrationCode': registrationController.text.trim(),
          'plan': planController.text.trim(),
          'isSaaSActive': isSaaSActive,
        });

        if (ownerUid.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
            'name': ownerNameController.text.trim(),
            'email': ownerEmailController.text.trim(),
            'contactNumber': ownerContactController.text.trim(),
          });
        }
      }

      // SAVE Merchant Credentials
      final merchantCol = FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('merchantCredentials');

      for (var merchant in merchantList) {
        if (merchant.gateway.isEmpty) continue;

        if (merchant.id.isEmpty) {
          // new
          await merchantCol.add({
            'gateway': merchant.gateway,
            'storeId': merchant.storeId,
            'hashKey': merchant.hashKey,
            'accountNumber': merchant.accountNumber,
            'environment': merchant.environment,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        } else {
          // update
          await merchantCol.doc(merchant.id).update({
            'gateway': merchant.gateway,
            'storeId': merchant.storeId,
            'hashKey': merchant.hashKey,
            'accountNumber': merchant.accountNumber,
            'environment': merchant.environment,
            'updatedAt': Timestamp.now(),
          });
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildMerchantForm() {
    return Column(
      children: [
        ...merchantList.asMap().entries.map((entry) {
          final index = entry.key;
          final merchant = entry.value;

          return Card(
            color: Colors.white10,
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text("Merchant ${index + 1}", style: const TextStyle(color: Colors.white))),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                       onPressed: () async {
  final merchantId = merchant.id;

  // 1. If it exists in Firestore, delete it there first
  if (widget.gymId != null && merchantId.isNotEmpty) {
    bool confirm = await _showDeleteConfirmation();
    if (!confirm) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('merchantCredentials')
          .doc(merchantId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merchant deleted from database"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e"))
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. Remove from the local UI list
  setState(() => merchantList.removeAt(index));
},
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: merchant.gateway,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Gateway (e.g., easypaisa)", Icons.payment),
                    onChanged: (val) => merchant.gateway = val,
                  ),
                  TextFormField(
                    initialValue: merchant.storeId,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Store ID", Icons.store),
                    onChanged: (val) => merchant.storeId = val,
                  ),
                  TextFormField(
                    initialValue: merchant.hashKey,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Hash Key (Encrypted)", Icons.lock),
                    onChanged: (val) => merchant.hashKey = val,
                  ),
                  TextFormField(
                    initialValue: merchant.accountNumber,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Account Number", Icons.account_balance),
                    onChanged: (val) => merchant.accountNumber = val,
                  ),
                  TextFormField(
                    initialValue: merchant.environment,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Environment (sandbox|production)", Icons.cloud),
                    onChanged: (val) => merchant.environment = val,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => merchantList.add(MerchantCredential()));
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Merchant"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent, foregroundColor: Colors.black),
        ),
      ],
    );
  }


  InputDecoration _fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.yellowAccent, size: 20),
      labelStyle: const TextStyle(color: Colors.white60),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellowAccent)),
    );
  }


Future<bool> _showDeleteConfirmation() async {
  return await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF121212),
      title: const Text("Delete Merchant?", style: TextStyle(color: Colors.white)),
      content: const Text("This will permanently remove these credentials.",
          style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  ) ?? false;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.gymId == null ? "ADD GYM" : "EDIT GYM", style: const TextStyle(letterSpacing: 2)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellowAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionHeader("GYM INFORMATION", Icons.store_rounded),
                    _buildFormCard([
                      TextFormField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Gym Name", Icons.badge)),
                      TextFormField(controller: locationController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Location", Icons.location_on)),
                      TextFormField(controller: feeController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Monthly Fee", Icons.payments), keyboardType: TextInputType.number),
                      TextFormField(controller: registrationController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Registration Code", Icons.qr_code)),
                      TextFormField(controller: planController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Plan (Monthly|6 Months|Yearly)", Icons.calendar_month)),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text("SaaS Platform Access", style: TextStyle(color: Colors.white, fontSize: 14)),
                        value: isSaaSActive,
                        activeColor: Colors.yellowAccent,
                        onChanged: (val) => setState(() => isSaaSActive = val),
                      ),
                    ]),
                    const SizedBox(height: 30),
                    _buildSectionHeader("OWNER INFORMATION", Icons.person_add_rounded),
                    _buildFormCard([
                      TextFormField(controller: ownerNameController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Owner Full Name", Icons.person)),
                      TextFormField(controller: ownerEmailController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Email Address", Icons.email)),
                      TextFormField(controller: ownerContactController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Contact Number", Icons.phone)),
                      if (widget.gymId == null)
                        TextFormField(controller: ownerPasswordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Temporary Password", Icons.lock)),
                    ]),
                    const SizedBox(height: 30),
                    _buildSectionHeader("MERCHANT CREDENTIALS", Icons.credit_card),
                    _buildMerchantForm(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveGym,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(widget.gymId == null ? "CREATE ACCOUNT" : "UPDATE DETAILS", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }


    Widget _buildFormCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }


}

class MerchantCredential {
  String id;
  String gateway;
  String storeId;
  String hashKey;
  String accountNumber;
  String environment;

  MerchantCredential({
    this.id = '',
    this.gateway = '',
    this.storeId = '',
    this.hashKey = '',
    this.accountNumber = '',
    this.environment = 'sandbox',
  });

  factory MerchantCredential.fromMap(Map<String, dynamic> map, String docId) {
    return MerchantCredential(
      id: docId,
      gateway: map['gateway'] ?? '',
      storeId: map['storeId'] ?? '',
      hashKey: map['hashKey'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      environment: map['environment'] ?? 'sandbox',
    );
  }
}






