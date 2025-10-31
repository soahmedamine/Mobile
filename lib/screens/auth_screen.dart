import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const AuthScreen({
    Key? key,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PageView for Login and Register
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Pass the onLoginSuccess callback to LoginScreen
                  LoginScreen(
                    onLoginSuccess: widget.onLoginSuccess,
                  ),
                  // Pass the onLoginSuccess callback to RegisterScreen as well
                  // since it might navigate to login after successful registration
                  RegisterScreen(
                    onLoginSuccess: widget.onLoginSuccess,
                  ),
                ],
              ),
            ),
            
            // Page indicator dots
            Container(
              padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(2, (int index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentPage == index ? 24.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: _currentPage == index 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey[400],
                    ),
                  );
                }),
              ),
            ),
            
            // Toggle button
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: TextButton(
                onPressed: () {
                  final nextPage = _currentPage == 0 ? 1 : 0;
                  _pageController.animateToPage(
                    nextPage,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  _currentPage == 0 
                      ? 'Create an account' 
                      : 'Already have an account? Sign In',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
