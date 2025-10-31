import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../database/auth_database_helper.dart';

class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._internal();
  final AuthDatabaseHelper _authDb = AuthDatabaseHelper();
  final String _googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  final String _googleRedirectUri = 'com.your.app:/oauth2redirect';
  
  // Store the auth state
  String? _accessToken;
  String? _idToken;
  String? _userEmail;
  String? _userName;
  
  factory SocialAuthService() => _instance;
  
  SocialAuthService._internal();

  // Sign in with Google
  Future<Map<String, dynamic>?>
      signInWithGoogle() async {
    try {
      // This is a simplified version that will need to be implemented
      // with your actual OAuth flow
      debugPrint('Initiating Google Sign In');
      
      // TODO: Implement the actual OAuth flow here
      // For now, we'll simulate a successful login
      final simulatedUser = {
        'username': 'Google User',
        'email': 'user@example.com',
        'id': 'google_123',
        'provider': 'google',
      };
      
      // Create or update user in local database
      final userId = await _authDb.createOrUpdateSocialUser(
        username: simulatedUser['username']!,
        email: simulatedUser['email']!,
        provider: 'google',
        authId: simulatedUser['id']!,
      );

      // Get the updated user data
      final user = await _authDb.getUserById(userId);
      
      if (user != null) {
        // Save login state
        await _saveLoginState(user);
        return user;
      }
      
      return null;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return null;
    }
  }

  // Sign in with Facebook - Not implemented in this version
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    // Facebook login is not implemented in this version
    debugPrint('Facebook login is not implemented in this version');
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      
      // Clear local state
      _accessToken = null;
      _idToken = null;
      _userEmail = null;
      _userName = null;
      
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  // Save login state to shared preferences
  Future<void> _saveLoginState(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('user_id', user['id']);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId != null) {
        return await _authDb.getUserById(userId);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
}
