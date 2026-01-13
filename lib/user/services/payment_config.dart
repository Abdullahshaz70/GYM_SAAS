import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';


class PaymentConfig {
  static const Map<String, Map<String, dynamic>> plans = {
    'Monthly': {
      'months': 1,
      'priceMultiplier': 1.0,
      'label': '1 Month'
    },
    '6 Months': {
      'months': 6,
      'priceMultiplier': 5.0, // Discounted rate
      'label': '6 Months'
    },
    'Yearly': {
      'months': 12,
      'priceMultiplier': 9.0, // Professional discount
      'label': 'Annual'
    },
  };

  static double calculatePrice(double baseFee, String planName) {
    final plan = plans[planName] ?? plans['Monthly']!;
    return baseFee * plan['priceMultiplier'];
  }
}