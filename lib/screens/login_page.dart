import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Función para redirigir según el rol del usuario.
  Future<void> _redirectUser(User user) async {
    // Consulta el documento del usuario en la colección 'usuarios'
    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    bool isAdmin = false;
    if (userDoc.exists && userDoc.data() != null) {
      isAdmin = userDoc.data()!['isAdmin'] ?? false;
    }
    // Redirige según el rol
    if (isAdmin) {
      Navigator.pushReplacementNamed(context, '/adminPanel');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Redirige según el rol del usuario
      await _redirectUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Inicia el flujo de autenticación con Google.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // El usuario canceló el proceso de sign in.
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Intenta guardar la información del usuario en Firestore (si aún no existe).
      try {
        final userDocRef = FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid);
        if (!(await userDocRef.get()).exists) {
          await userDocRef.set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            // Por defecto, se asigna isAdmin en false.
            'isAdmin': false,
          });
        }
      } catch (e) {
        print("Error al guardar datos en Firestore: $e");
      }
      // Redirige según el rol del usuario.
      await _redirectUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión con Google';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loginWithEmail,
                      child: const Text('Iniciar sesión'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('O'),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _loginWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión con Google'),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Registrar nuevo usuario'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16.0),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
