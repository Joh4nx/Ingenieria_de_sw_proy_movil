import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

// Widget estático para el nombre de la app con diseño premium
class StaticAppName extends StatelessWidget {
  const StaticAppName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Efecto de fondo degradado con colores suaves que combinan con la app
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF8E1), // Light yellow suave
                Color(0xFFFFECB3), // Amber claro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ).createShader(bounds),
            child: Text(
              "KHYNGO",
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Efecto de borde dinámico
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: const GradientBorder(
                gradient: LinearGradient(
                  colors: [
                    Colors.white70,
                    Colors.white30,
                  ],
                ),
                width: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// Clase personalizada para bordes con degradado
// Clase personalizada para bordes con degradado
class GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const GradientBorder({
    required this.gradient,
    this.width = 1.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
      Canvas canvas,
      Rect rect, {
        TextDirection? textDirection,
        BoxShape shape = BoxShape.rectangle,
        BorderRadius? borderRadius,
      }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final RRect rrect = borderRadius?.toRRect(rect) ??
        (shape == BoxShape.circle
            ? RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2))
            : RRect.fromRectAndRadius(rect, Radius.zero));
    canvas.drawRRect(rrect, paint);
  }

  @override
  BoxBorder scale(double t) => this;

  // Implementaciones requeridas por BoxBorder
  @override
  BorderSide get top => BorderSide(color: Colors.transparent, width: width);

  @override
  BorderSide get bottom => BorderSide(color: Colors.transparent, width: width);

  @override
  BorderSide get left => BorderSide(color: Colors.transparent, width: width);

  @override
  BorderSide get right => BorderSide(color: Colors.transparent, width: width);

  @override
  bool get isUniform => true;
}


// Widget para el botón con degradado profesional
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;
  final double width;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.height = 50,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definición de colores
    const Color amarilloVibrante = Color(0xFFFFD700);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            amarilloVibrante,
            Color(0xFFFFE600),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Clipper personalizado para un encabezado que ocupa toda la parte superior
class FullWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Comenzamos en la esquina superior izquierda
    path.lineTo(0, size.height - 50);
    // Onda central
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Segunda parte de la onda
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Lado derecho hacia arriba
    path.lineTo(size.width, 0);
    // Cerrar el camino
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Paleta de colores (con amarillo predominante)
  final Color amarilloVibrante = const Color(0xFFFFD700);
  final Color verdePradera = const Color(0xFF4CAF50);
  final Color azulProfesional = const Color(0xFF2196F3);
  final Color blanco = Colors.white;
  final Color grisSuave = const Color(0xFFF5F5F5);

  Future<void> _redirectUser(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    bool isAdmin = false;
    if (userDoc.exists && userDoc.data() != null) {
      isAdmin = userDoc.data()!['isAdmin'] ?? false;
    }
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
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      try {
        final userDocRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid);
        if (!(await userDocRef.get()).exists) {
          await userDocRef.set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'isAdmin': false,
          });
        }
      } catch (e) {
        print("Error al guardar datos en Firestore: $e");
      }
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

  // Encabezado que muestra el logo y el nombre de la app
  Widget _buildHeader(double screenWidth) {
    return ClipPath(
      clipper: FullWaveClipper(),
      child: Container(
        width: screenWidth,
        height: 260,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              amarilloVibrante.withOpacity(0.85),
              amarilloVibrante.withOpacity(0.65)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo en un círculo
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Nombre de la app con diseño premium
              const StaticAppName(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: blanco,
        body: SafeArea(
          child: Stack(
            children: [
              // Fondo general
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [amarilloVibrante.withOpacity(0.15), blanco],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    _buildHeader(screenWidth),
                    const SizedBox(height: 16),
                    // Caja principal para el formulario con elevación mejorada
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 12,
                      shadowColor: amarilloVibrante.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (_errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7675)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFFF7675)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Color(0xFFFF7675)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                              color: Color(0xFFFF7675)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                  FloatingLabelBehavior.auto,
                                  labelText: "Correo electrónico",
                                  labelStyle: TextStyle(
                                    color: verdePradera,
                                    fontSize: 16,
                                  ),
                                  prefixIcon:
                                  Icon(Icons.email, color: verdePradera),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: grisSuave,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: amarilloVibrante, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Por favor ingresa tu correo";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  floatingLabelBehavior:
                                  FloatingLabelBehavior.auto,
                                  labelText: "Contraseña",
                                  labelStyle: TextStyle(
                                    color: verdePradera,
                                    fontSize: 16,
                                  ),
                                  prefixIcon:
                                  Icon(Icons.lock, color: verdePradera),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: grisSuave,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: amarilloVibrante, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Por favor ingresa tu contraseña";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              // Botón de inicio de sesión con degradado profesional
                              GradientButton(
                                text: "Iniciar sesión",
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _loginWithEmail();
                                },
                                height: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Separador
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                              color: grisSuave,
                              thickness: 1,
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("O",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700])),
                        ),
                        Expanded(
                            child: Divider(
                              color: grisSuave,
                              thickness: 1,
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Botón de inicio de sesión con Google con efectos de profundidad mejorados
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 24,
                        ),
                        label: Text(
                          "Continuar con Google",
                          style: TextStyle(
                            color: azulProfesional,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blanco,
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: grisSuave),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _loginWithGoogle();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Opciones: Registro y Olvido de contraseña
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          "Registrar nuevo usuario",
                          style: TextStyle(
                            color: azulProfesional,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: azulProfesional,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(
                          color: amarilloVibrante,
                          strokeWidth: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
