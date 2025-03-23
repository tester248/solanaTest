import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/vendor_screen.dart';
import '../services/auth_service.dart';
import '../utils/navigation_utils.dart';
import 'register_screen.dart';
import 'student_screen.dart';
import 'parent_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }
  
  Future<void> _checkCurrentUser() async {
    setState(() => _isLoading = true);
    
    final currentUser = await _authService.getCurrentUser();
    
    if (currentUser != null) {
      _navigateBasedOnRole(currentUser.role);
    }
    
    setState(() => _isLoading = false);
  }
  
  void _navigateBasedOnRole(String role) {
    if (role == 'student') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentScreen())
      );
    } else if (role == 'parent') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ParentScreen())
      );
    }
    else if (role == 'vendor') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VendorScreen())
      );
    }
  }

  void _onLoginSuccess(String role) {
    switch (role) {
      case 'student':
        NavigationUtils.pushAndRemoveUntil(context, StudentScreen());
        break;
      case 'parent':
        NavigationUtils.pushAndRemoveUntil(context, ParentScreen());
        break;
      case 'vendor':
        NavigationUtils.pushAndRemoveUntil(context, VendorScreen());
        break;
    }
  }
  
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      try {
        final user = await _authService.login(_username, _password);
        
        if (user != null) {
          _navigateBasedOnRole(user.role);
        } else {
          setState(() {
            _errorMessage = 'Invalid username or password';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                    onSaved: (value) => _username = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value!,
                  ),
                  SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _login,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RegisterScreen())
                      );
                    },
                    child: Text('Don\'t have an account? Register'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
