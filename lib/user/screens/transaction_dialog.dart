import 'package:flutter/material.dart';

class TransactionDialog extends StatefulWidget {
  final double amount;
  const TransactionDialog({super.key, required this.amount});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final TextEditingController _tidController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      title: const Text("Confirm Transfer", style: TextStyle(color: Colors.yellowAccent)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Please transfer Rs. ${widget.amount} to:", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          const Text("Easypaisa: 0300-1234567", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Text("Name: Gym Owner Name", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          TextField(
            controller: _tidController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter Transaction ID",
              hintStyle: const TextStyle(color: Colors.white24),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.yellowAccent)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent),
          onPressed: () => Navigator.pop(context, _tidController.text.trim()),
          child: const Text("VERIFY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}