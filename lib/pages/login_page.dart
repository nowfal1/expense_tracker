import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:exp_tracker/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  FocusNode _emailFocus = FocusNode();
  FocusNode _passwordFocus = FocusNode();
  late final AnimationController _lottieController;
  bool _isFieldFocused = false;
  bool _obscurePassword = true;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _emailFocus.addListener(_handleFocusChange);
    _passwordFocus.addListener(_handleFocusChange);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset =
          _scrollController.hasClients ? _scrollController.offset : 0.0;
    });
  }

  void _handleFocusChange() {
    setState(() {
      _isFieldFocused = _emailFocus.hasFocus || _passwordFocus.hasFocus;
      if (_isFieldFocused) {
        _lottieController.forward(from: 0); // Play animation
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _lottieController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _trySilentSignIn() async {
    if (kIsWeb) {
      try {
        await AuthService.googlesignin.signInSilently();
      } catch (e) {
        _showError("Silent sign-in failed: $e");
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await AuthService.googlesignin.signIn();
      Navigator.pushReplacementNamed(context, '/exp');
    } catch (e) {
      _showError("Google sign-in failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/exp');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login Failed");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Error in Logging In'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final lottieStartAlign = Alignment.topCenter;
    final lottieEndAlign = Alignment.bottomCenter;
    final cardStartAlign = Alignment.center;
    final cardEndAlign = Alignment.topCenter;
    // Calculate animation value (0.0 at top, 1.0 at max scroll)
    final maxScroll = 200.0;
    final t = (_scrollOffset / maxScroll).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF123953), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Animated Lottie
            AnimatedAlign(
              alignment: Alignment.lerp(lottieStartAlign, lottieEndAlign, t)!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 40 + (screenHeight * 0.1) * (1 - t),
                  bottom: 40 + (screenHeight * 0.1) * t,
                ),
                child: SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    'assets/See no evil.json',
                    controller: _lottieController,
                    onLoaded: (composition) {
                      _lottieController.duration = composition.duration;
                    },
                    repeat: false,
                    animate: _isFieldFocused,
                  ),
                ),
              ),
            ),
            // Animated Card
            AnimatedAlign(
              alignment: Alignment.lerp(cardStartAlign, cardEndAlign, t)!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  top: 180,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: isDark ? Colors.grey[900] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Expense Tracker",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Track your spending, save more!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Email TextField
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password TextField
                        TextField(
                          controller: _passController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password navigation
                              _showError(
                                "Forgot password functionality coming soon!",
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Login Button
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                        const SizedBox(height: 16),
                        // Register Button (no loading state)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Colors.blueAccent),
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("or"),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Image.network(
                              'https://static.vecteezy.com/system/resources/previews/028/667/072/non_2x/google-logo-icon-symbol-free-png.png',
                              height: 24,
                              width: 24,
                            ),
                            label: const Text('Sign in with Google'),
                            onPressed: _signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.black12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
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
