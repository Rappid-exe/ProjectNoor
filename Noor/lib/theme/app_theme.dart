import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Inter',
    
    // Remove or update AppBar theme since we're not using AppBars anymore
    // You can keep it for any future screens that might use AppBars
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.blue.shade800),
      titleTextStyle: TextStyle(
        color: Colors.blue.shade800, 
        fontSize: 20, 
        fontWeight: FontWeight.bold
      ),
    ),
    
    // Keep other theme settings
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      buttonColor: Colors.blue,
    ),
    
    // Add text theme for consistency across screens
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.blue.shade800,
      ),
    ),
  );
}