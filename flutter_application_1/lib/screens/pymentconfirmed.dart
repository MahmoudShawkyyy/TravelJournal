import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/mainn.dart'; // Assuming TravelApp is located in this file

class PaymentConfirmedPage extends StatefulWidget {
  final String username; // Accept username as a parameter

  const PaymentConfirmedPage({Key? key, required this.username})
      : super(key: key);

  @override
  State<PaymentConfirmedPage> createState() => _PaymentConfirmedPageState();
}

class _PaymentConfirmedPageState extends State<PaymentConfirmedPage> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  String _ratingFeedback = "";

  Future<void> submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a rating before submitting.')),
      );
      return;
    }

    // Set feedback message based on rating
    if (_selectedRating == 5) {
      _ratingFeedback = "Excellent";
    } else if (_selectedRating == 4) {
      _ratingFeedback = "Very Good";
    } else if (_selectedRating == 3) {
      _ratingFeedback = "Good";
    } else if (_selectedRating == 2) {
      _ratingFeedback = "Fair";
    } else if (_selectedRating == 1) {
      _ratingFeedback = "Poor";
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('service_ratings').add({
          'userId': currentUser.uid,
          'username': widget.username, // Use the passed username
          'rating': _selectedRating,
          'feedback': _ratingFeedback, // Store feedback in the database
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Thank you for your feedback! ($_ratingFeedback)')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TravelApp(),
          ),
        );
      } else {
        throw Exception('User not authenticated.');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $error')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('Payment Confirmed'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://marketplace.canva.com/EAF6acpWphQ/2/0/1600w/canva-brown-colorful-travel-photo-collage-sJLlU2R3gLs.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.brown,
                  size: 80.0,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 252, 251, 248)),
                  child: const Text(
                    'Your payment has been successfully confirmed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Star rating widget
                Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Text(
                    'Rate our service:',
                    style: TextStyle(
                      fontSize: 24,
                      color: const Color.fromARGB(255, 255, 210, 8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: const Color.fromARGB(255, 255, 223, 41),
                        size: 40,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : submitRating,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 20),

                // Back to Home button
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TravelApp(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
