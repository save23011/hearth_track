import 'package:Soulene/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.success && response.user != null && response.token != null) {
        await ApiService.setAuthData(response.token!, response.user!.toJson());
        // Login successful
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Login failed
        if (mounted) {
          _showErrorSnackBar(response.message ?? 'Login failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Network error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToRegister() {
    Navigator.of(context).pushNamed('/register');
  }

  void _goToForgotPassword() {
    // TODO: Implement forgot password navigation
    _showErrorSnackBar('Forgot password feature coming soon!');
  }

  Future<void> _loginWithGoogle() async {
    // TODO: Implement Google Sign-In
    _showErrorSnackBar('Google Sign-In coming soon!');
  }

  Future<void> _loginWithFacebook() async {
    // TODO: Implement Facebook Sign-In
    _showErrorSnackBar('Facebook Sign-In coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body:Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFDEF3FD), Color(0xFFF0DEFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LoadingOverlay(
        isLoading: _isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenHeight*0.05),
                  // App Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        "assets/icons/brain_outline.png",
                        color: Colors.white,
                        height: 50,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight*0.01 ),

                  // Welcome Text
              ShaderMask(
                // Define the gradient
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [AppTheme.primaryColor, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                // The blend mode determines how the gradient interacts with the text
                blendMode: BlendMode.srcIn,
                // The Text widget to which the gradient will be applied
                child:
                  Text(
                    'Welcome Back!',
                    style: AppTheme.heading1.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ),

                  SizedBox(height: screenHeight*0.004),

                  Text(
                    'Sign in to continue your wellness journey',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                   SizedBox(height: screenHeight*0.03),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: screenHeight*0.02),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: screenHeight*0.01),

                  // Remember Me & Forgot Password
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                     // autofocus: true,
                        side: BorderSide(color: Colors.grey),
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      Text(
                        'Remember me',
                        style: AppTheme.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _goToForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight*0.01 ),

                  // Login Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),

                  SizedBox(height: screenHeight*0.02),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.black38,)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR continue with',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.black38)),
                    ],
                  ),

                  SizedBox(height: screenHeight*0.02),

                  // Social Login Buttons
                  _SocialLoginButton(
                    text: 'Continue with Google',
                    icon: Image.asset("assets/icons/google.png"),
                    onPressed: _loginWithGoogle,
                    backgroundColor: Colors.white,
                    textColor: AppTheme.textPrimary,
                    borderColor: AppTheme.borderLight,
                  ),

                   SizedBox(height: screenHeight*0.01),

                  _SocialLoginButton(
                    text: 'Continue with Facebook',
                    icon: Icon(Icons.facebook),
                    onPressed: _loginWithFacebook,
                    backgroundColor: const Color(0xFF1877F2),
                    textColor: Colors.white,
                  ),

                   SizedBox(height: screenHeight*0.03),

                  // Sign Up Link
                      Text(
                        "Don't have an account? ",
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                  ),
              SizedBox(height:screenHeight*0.01 ,),
               Center(
                 child: OutlinedButton(
                    onPressed: _goToRegister,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(
                        color: AppTheme.primaryColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    ),
                       child: Text(
                          "Create Free Account",
                          style: AppTheme.button.copyWith(color: AppTheme.primaryColor),
                        ),
                    ),
               ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialLoginButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor ?? backgroundColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(child:icon, height: 20 , width: 20,),
            const SizedBox(width: 12),
            Text(
              text,
              style: AppTheme.button.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
