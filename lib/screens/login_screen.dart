import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_weather_app/database/auth_database_helper.dart';
import 'package:smart_travel_weather_app/services/social_auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const LoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late AuthDatabaseHelper _authDb;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRecaptchaVerified = false;
  bool _showRecaptcha = false;
  String? _errorMessage;
  final String _recaptchaSiteKey = '6Lfu5vorAAAAANmMhKAN8jAF43vTorscFpSjU_SX';
  final String _recaptchaSecretKey = 'YOUR_SECRET_KEY'; // Replace with your actual secret key from Google reCAPTCHA admin console
  final Completer<InAppWebViewController> _webViewController = Completer<InAppWebViewController>();


  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _authDb = AuthDatabaseHelper();
    
    // Initialize the database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDatabase();
    });
  }
  
  Future<void> _initDatabase() async {
    try {
      await _authDb.database; // This will initialize the database
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error initializing database. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _verifyRecaptcha() async {
    setState(() {
      _showRecaptcha = true;
    });
    
    // Wait for the user to complete the reCAPTCHA
    final completer = Completer<bool>();
    
    // This will be called when the user completes the reCAPTCHA
    void onRecaptchaVerified(bool success) {
      setState(() {
        _showRecaptcha = false;
        _isRecaptchaVerified = success;
      });
      completer.complete(success);
    }
    
    // Show the reCAPTCHA dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify you\'re human'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('data:text/html;charset=utf-8,' + Uri.encodeComponent('''
                  <!DOCTYPE html>
                  <html>
                  <head>
                    <title>reCAPTCHA Demo</title>
                    <script src="https://www.google.com/recaptcha/api.js" async defer></script>
                    <style>
                      body { margin: 0; padding: 20px; display: flex; justify-content: center; align-items: center; height: 100%; }
                      .g-recaptcha { transform: scale(0.9); transform-origin: 0 0; }
                    </style>
                  </head>
                  <body>
                    <div class="g-recaptcha" 
                         data-sitekey="${_recaptchaSiteKey}" 
                         data-callback="onRecaptchaSuccess"
                         data-expired-callback="onRecaptchaExpired"
                         data-error-callback="onRecaptchaError">
                    </div>
                    <script>
                      function onRecaptchaSuccess(token) {
                        window.flutter_inappwebview.callHandler('onRecaptchaSuccess', token);
                      }
                      function onRecaptchaExpired() {
                        window.flutter_inappwebview.callHandler('onRecaptchaExpired');
                      }
                      function onRecaptchaError() {
                        window.flutter_inappwebview.callHandler('onRecaptchaError');
                      }
                    </script>
                  </body>
                  </html>
                ''')),
              ),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                ),
              ),
              onWebViewCreated: (controller) {
                _webViewController.complete(controller);
                controller.addJavaScriptHandler(
                  handlerName: 'onRecaptchaSuccess',
                  callback: (args) {
                    Navigator.of(context).pop();
                    onRecaptchaVerified(true);
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'onRecaptchaExpired',
                  callback: (args) {
                    setState(() {
                      _errorMessage = 'reCAPTCHA expired. Please try again.';
                    });
                    Navigator.of(context).pop();
                    onRecaptchaVerified(false);
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'onRecaptchaError',
                  callback: (args) {
                    setState(() {
                      _errorMessage = 'Error verifying reCAPTCHA. Please try again.';
                    });
                    Navigator.of(context).pop();
                    onRecaptchaVerified(false);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRecaptchaVerified(false);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    
    return await completer.future;
  }

  Future<void> _login() async {
    debugPrint('🔵 [LOGIN] _login() called');
    
    try {
      // First, check if the form key and its current state are not null
      if (_formKey.currentState == null) {
        debugPrint('❌ [LOGIN] Form state is null. Form key: $_formKey');
        if (mounted) {
          setState(() {
            _errorMessage = 'Form initialization error. Please try again.';
          });
        }
        return;
      }

      debugPrint('🔵 [LOGIN] Validating form...');
      // Then validate the form
      if (!_formKey.currentState!.validate()) {
        debugPrint('❌ [LOGIN] Form validation failed');
        return;
      }
      debugPrint('✅ [LOGIN] Form validation passed');

      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Temporarily disable reCAPTCHA for testing
      debugPrint('⚠️ [LOGIN] reCAPTCHA verification is temporarily disabled for testing');
      _isRecaptchaVerified = true;
      
      debugPrint('🔵 [LOGIN] Calling _performLogin()...');
      await _performLogin();
      debugPrint('✅ [LOGIN] _performLogin() completed');
    } catch (e, stackTrace) {
      debugPrint('❌ [LOGIN] Unexpected error in _login(): $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performLogin() async {
    if (!mounted) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    debugPrint('🔑 [LOGIN] Starting login process for: $email');
    
    try {
      debugPrint('🔍 [LOGIN] Attempting to authenticate user: $email');
      
      // Authenticate with database
      final user = await _authDb.getUserByCredentials(email, password);
      
      if (user != null && user.isNotEmpty) {
        debugPrint('✅ [LOGIN] Authentication successful for user: ${user['email']}');
        
        // Save login state
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_email', email);
          await prefs.setString('user_role', user['role'] ?? 'user');
          debugPrint('💾 [LOGIN] Saved login state to SharedPreferences');
        } catch (e) {
          debugPrint('❌ [LOGIN] Error saving login state: $e');
        }
        
        if (mounted) {
          debugPrint('🔄 [LOGIN] Resetting reCAPTCHA state');
          // Reset reCAPTCHA after successful login
          if (_isRecaptchaVerified) {
            setState(() {
              _isRecaptchaVerified = false;
            });
          }
          
          debugPrint('🚀 [LOGIN] Handling successful login');
          // Reset loading state before navigation
          setState(() {
            _isLoading = false;
          });
          
          if (widget.onLoginSuccess != null) {
            debugPrint('   ↳ Using provided onLoginSuccess callback');
            widget.onLoginSuccess!();
          } else {
            debugPrint('   ↳ Navigating to HomeScreen');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        }
      } else {
        debugPrint('❌ [LOGIN] Login failed: No user found or invalid credentials');
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid email or password';
            _isLoading = false;
            // Reset reCAPTCHA on failed login
            if (_isRecaptchaVerified) {
              _isRecaptchaVerified = false;
            }
          });
        }
      }
    } on Exception catch (e) {
      debugPrint('❌ [LOGIN] Login error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
          // Reset reCAPTCHA on error
          if (_isRecaptchaVerified) {
            _isRecaptchaVerified = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Stack(
        children: [
          _buildMainContent(),
          if (_showRecaptcha)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // App Logo/Title
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Email Field
                Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800]!.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: Color(0xFF8D8D9E)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      debugPrint('🔍 [VALIDATION] Validating email: $value');
                      if (value == null || value.isEmpty) {
                        debugPrint('❌ [VALIDATION] Email is empty');
                        return 'Please enter your email';
                      }
                      // More permissive email validation
                      final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
                      if (!emailValid) {
                        debugPrint('❌ [VALIDATION] Invalid email format: $value');
                        return 'Please enter a valid email';
                      }
                      debugPrint('✅ [VALIDATION] Email is valid');
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                Text(
                  'Password',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800]!.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(color: Color(0xFF8D8D9E)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error Message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFF3B30), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                color: Colors.red[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      debugPrint('🔄 [UI] Login button pressed');
                      try {
                        _login();
                      } catch (e, stackTrace) {
                        debugPrint('❌ [UI] Error in login button handler: $e');
                        debugPrint('Stack trace: $stackTrace');
                        if (mounted) {
                          setState(() {
                            _errorMessage = 'An error occurred. Please try again.';
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider with "or"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.blue[700]!.withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8D8D9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.blue[700]!.withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.blue[800]!.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3A3A4A)),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          try {
                            final socialAuth = SocialAuthService();
                            final user = await socialAuth.signInWithGoogle();
                            if (user != null && mounted) {
                              if (widget.onLoginSuccess != null) {
                                widget.onLoginSuccess!();
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error signing in with Google: $e'),
                                  backgroundColor: const Color(0xFFFF3B30),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: Image.asset(
                          'assets/images/google.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Apple
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.blue[800]!.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3A3A4A)),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Apple sign in coming soon!'),
                              backgroundColor: const Color(0xFF6C5CE7),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(
                              onLoginSuccess: widget.onLoginSuccess,
                              onRegisterSuccess: widget.onLoginSuccess,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}