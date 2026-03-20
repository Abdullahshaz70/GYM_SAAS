import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GymAccount {
  String bankName;
  String accountTitle;
  String accountNumber;
  String accountType;

  GymAccount({
    this.bankName = '',
    this.accountTitle = '',
    this.accountNumber = '',
    this.accountType = 'Bank Account',
  });

  factory GymAccount.fromMap(Map<String, dynamic> map) {
    return GymAccount(
      bankName: map['bankName'] ?? '',
      accountTitle: map['accountTitle'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountType: map['accountType'] ?? 'Bank Account',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountTitle': accountTitle,
      'accountNumber': accountNumber,
      'accountType': accountType,
    };
  }
}

class AddEditGymScreen extends StatefulWidget {
  final String? gymId;
  const AddEditGymScreen({super.key, this.gymId});

  @override
  State<AddEditGymScreen> createState() => _AddEditGymScreenState();
}

class _AddEditGymScreenState extends State<AddEditGymScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController registrationController = TextEditingController();
  final TextEditingController planController = TextEditingController();

  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerEmailController = TextEditingController();
  final TextEditingController ownerContactController = TextEditingController();
  final TextEditingController ownerPasswordController = TextEditingController();
  final TextEditingController statusController = TextEditingController();


  bool isSaaSActive = true;
  bool isLoading = false;
  String ownerUid = "";
  List<GymAccount> accountList = [];

  @override
  void initState() {
    super.initState();
    if (widget.gymId != null) {
      _loadGymData();
    } else {
      accountList.add(GymAccount());
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
      statusController.text = data['status'] ?? '';
      
      if (data['depositAccounts'] != null) {
        accountList = (data['depositAccounts'] as List)
            .map((item) => GymAccount.fromMap(item as Map<String, dynamic>))
            .toList();
      }
      if (accountList.isEmpty) accountList.add(GymAccount());
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

  Future<void> _saveGym() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> accountsData = accountList
          .where((acc) => acc.bankName.isNotEmpty && acc.accountNumber.isNotEmpty)
          .map((acc) => acc.toMap())
          .toList();

      Map<String, dynamic> gymData = {
        'gymName': nameController.text.trim(),
        'location': locationController.text.trim(),
        'defaultFee': num.tryParse(feeController.text) ?? 0,
        'registrationCode': registrationController.text.trim(),
        'plan': planController.text.trim(),
        'status': statusController.text.trim(),
        'isSaaSActive': isSaaSActive,
        'depositAccounts': accountsData,
      };

      if (widget.gymId == null) {
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
          'status': statusController.text.trim(),
          'contactNumber': ownerContactController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        gymData['status'] = 'active';
        gymData['createdAt'] = Timestamp.now();
        gymData['ownerUid'] = ownerUid;
        if (registrationController.text.isEmpty) {
          gymData['registrationCode'] = DateTime.now().millisecondsSinceEpoch.toString();
        }

        final gymRef = await FirebaseFirestore.instance.collection('gyms').add(gymData);
        await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({'gymId': gymRef.id});
      } else {
        await FirebaseFirestore.instance.collection('gyms').doc(widget.gymId).update(gymData);

        if (ownerUid.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(ownerUid).update({
            'name': ownerNameController.text.trim(),
            'email': ownerEmailController.text.trim(),
            'contactNumber': ownerContactController.text.trim(),
          });
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildAccountForm() {
    return Column(
      children: [
        ...accountList.asMap().entries.map((entry) {
          final index = entry.key;
          final account = entry.value;

          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(top: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Account #${index + 1}", 
                        style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                        onPressed: () => setState(() => accountList.removeAt(index)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _typeChip("Bank Account", account),
                      const SizedBox(width: 10),
                      _typeChip("Wallet (EP/JC)", account),
                    ],
                  ),
                  TextFormField(
                    initialValue: account.bankName,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Bank Name (e.g. Meezan, Easypaisa)", Icons.account_balance),
                    onChanged: (val) => account.bankName = val,
                  ),
                  TextFormField(
                    initialValue: account.accountTitle,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle("Account Title", Icons.person_pin),
                    onChanged: (val) => account.accountTitle = val,
                  ),
                  TextFormField(
                    initialValue: account.accountNumber,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldStyle(
                      account.accountType == "Bank Account" ? "IBAN / Account Number" : "Mobile Number", 
                      Icons.numbers
                    ),
                    onChanged: (val) => account.accountNumber = val,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => setState(() => accountList.add(GymAccount())),
          icon: const Icon(Icons.add),
          label: const Text("Add Account"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent, foregroundColor: Colors.black),
        ),
      ],
    );
  }

  Widget _typeChip(String label, GymAccount account) {
    bool isSelected = account.accountType == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      onSelected: (val) => setState(() => account.accountType = label),
      selectedColor: Colors.yellowAccent,
      backgroundColor: Colors.white10,
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
                      TextFormField(controller: planController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("Plan", Icons.calendar_month)),
                      TextFormField(controller: statusController, style: const TextStyle(color: Colors.white), decoration: _fieldStyle("status", Icons.info)),
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
                    _buildSectionHeader("DEPOSIT ACCOUNTS", Icons.account_balance_wallet),
                    _buildAccountForm(),
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
}