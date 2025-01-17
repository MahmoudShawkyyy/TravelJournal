import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/pymentconfirmed.dart';
import 'package:flutter_credit_card/credit_card_form.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';

class PaymentPage extends StatefulWidget {
  final double totalCost;
  final Map<String, dynamic> bookingData;

  const PaymentPage(
      {super.key, required this.totalCost, required this.bookingData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool isLoading = false;

  Future<void> savePaymentDetails() async {
    if (cardNumber.isEmpty ||
        expiryDate.isEmpty ||
        cardHolderName.isEmpty ||
        cvvCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all payment details')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final paymentData = {
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cardHolderName': cardHolderName,
      'cvvCode': cvvCode,
      'totalCost': widget.totalCost,
      'paymentDate': Timestamp.now(),
      'paymentStatus': true, // Payment confirmed flag
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('payments')
          .add(paymentData);

      await saveToConfirmedPayments(docRef.id, paymentData);
      await saveTripDetails(docRef.id, paymentData);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentConfirmedPage(username: 'name'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process payment: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveToConfirmedPayments(
      String paymentId, Map<String, dynamic> paymentData) async {
    try {
      await FirebaseFirestore.instance
          .collection('confirmed_payments')
          .doc(paymentId)
          .set({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        ...paymentData,
      });
    } catch (error) {
      print("Error saving confirmed payment: $error");
    }
  }

  Future<void> saveTripDetails(
      String paymentId, Map<String, dynamic> paymentData) async {
    final tripData = {
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'name': widget.bookingData['name'],
      'email': widget.bookingData['email'],
      'id': widget.bookingData['id'],
      'destination': widget.bookingData['destination'],
      'duration': widget.bookingData['duration'],
      'guests': widget.bookingData['guests'],
      'guestDetails': widget.bookingData['guestDetails'],
      'accommodation': widget.bookingData['accommodation'],
      'viewType': widget.bookingData['viewType'],
      'travelClass': widget.bookingData['travelClass'],
      'returnTravelClass': widget.bookingData['returnTravelClass'],
      'bookingTime': Timestamp.now(),
      'paymentStatus': true,
      'paymentId': paymentId,
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tripdetails')
          .add(tripData);

      await saveToConfirmedTrips(docRef.id, tripData);
    } catch (error) {
      print("Error saving trip details: $error");
    }
  }

  Future<void> saveToConfirmedTrips(
      String tripId, Map<String, dynamic> tripData) async {
    try {
      await FirebaseFirestore.instance
          .collection('confirmed_trips')
          .doc(tripId)
          .set({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        ...tripData,
      });
    } catch (error) {
      print("Error saving confirmed trip: $error");
    }
  }

  void userTappedPay() {
    if (formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Payment"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text("Card Number: $cardNumber"),
                Text("Expiry Date: $expiryDate"),
                Text("Card Holder Name: $cardHolderName"),
                Text("CVV: $cvvCode"),
                Text("Total Amount: \$${widget.totalCost.toStringAsFixed(2)}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                savePaymentDetails();
              },
              child: const Text("Confirm"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Checkout"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8CBA7), // Lightest brown
              Color(0xFFD7B59E), // Lighter brown
              Color(0xFF6A4E23), // Dark brown
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              CreditCardWidget(
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                showBackView: isCvvFocused,
                chipColor: Colors.deepPurpleAccent,
                onCreditCardWidgetChange: (p0) {},
              ),
              CreditCardForm(
                formKey: formKey,
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                themeColor: Colors.deepPurpleAccent,
                onCreditCardModelChange: (data) {
                  setState(() {
                    cardNumber = data.cardNumber;
                    expiryDate = data.expiryDate;
                    cardHolderName = data.cardHolderName;
                    cvvCode = data.cvvCode;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Total Amount: \$${widget.totalCost.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: userTappedPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Pay Now"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
