import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final List<Color> gradientColors; // Gradient colors for the button
  final double glowRadius; // Glow effect radius

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.textColor = Colors.white,
    this.gradientColors = const [Colors.blueAccent, Colors.purpleAccent], // Default gradient
    this.glowRadius = 1.0, // Default glow radius
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Rounded corners
          ),
          backgroundColor: Colors.transparent, // Transparent background
          shadowColor: Colors.transparent, // Remove default shadow
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Container(
            constraints: BoxConstraints(minWidth: 150.0, minHeight: 50.0),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2, // Add spacing for a modern look
              ),
            ),
          ),
        ),
      ),
    );
  }
}