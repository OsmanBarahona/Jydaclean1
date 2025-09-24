import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Función para mostrar mensajes (reemplaza FlutterToast)
  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Las contraseñas no coinciden';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Crear usuario en Firebase Auth
        final UserCredential userCredential = 
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Guardar información adicional en Firestore
        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'username': _emailController.text.split('@').first, // ✅ NUEVO: Generar username del email
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'client', // ✅ TODOS se crean como 'client' por defecto
            'status': 'active',
          });

          _showMessage(context, 'Cuenta creada exitosamente');

          // Navegar a la pantalla principal
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error al crear la cuenta';
        
        if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil (mínimo 6 caracteres)';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Ya existe una cuenta con este correo electrónico';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El correo electrónico no es válido';
        } else if (e.code == 'operation-not-allowed') {
          errorMessage = 'Operación no permitida';
        }

        setState(() {
          _errorMessage = errorMessage;
        });
        
        _showMessage(context, errorMessage, isError: true);
      } catch (e) {
        setState(() {
          _errorMessage = 'Error inesperado. Intenta nuevamente.';
        });
        
        _showMessage(context, 'Error inesperado. Intenta nuevamente.', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, 
                        FormFieldValidator<String> validator, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: _getPrefixIcon(label),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, 
                            FormFieldValidator<String> validator, bool isConfirm) {
    return TextFormField(
      controller: controller,
      obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            isConfirm ? 
              (_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off) :
              (_obscurePassword ? Icons.visibility : Icons.visibility_off),
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        ),
      ),
      validator: validator,
    );
  }

  Icon _getPrefixIcon(String label) {
    switch (label) {
      case 'Nombre Completo':
        return const Icon(Icons.person, color: Colors.grey);
      case 'Correo electrónico':
        return const Icon(Icons.email, color: Colors.grey);
      case 'Teléfono':
        return const Icon(Icons.phone, color: Colors.grey);
      default:
        return const Icon(Icons.text_fields, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF009CA8),
      appBar: AppBar(
        title: const Text("Registrarse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Completa la información siguiente para registrarte en nuestro sistema.",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Mensaje de error
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildTextField(
                  "Nombre Completo", 
                  "Ej: Juan Pérez", 
                  _nameController, 
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre completo';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  }, 
                  TextInputType.text
                ),
                
                const SizedBox(height: 12),
                
                _buildTextField(
                  "Correo electrónico", 
                  "correo@dominio.com", 
                  _emailController, 
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  }, 
                  TextInputType.emailAddress
                ),
                
                const SizedBox(height: 12),
                
                _buildTextField(
                  "Teléfono", 
                  "########", 
                  _phoneController, 
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu teléfono';
                    }
                    if (value.length < 8) {
                      return 'El teléfono debe tener al menos 8 dígitos';
                    }
                    return null;
                  }, 
                  TextInputType.phone
                ),
                
                const SizedBox(height: 12),
                
                _buildPasswordField(
                  "Contraseña", 
                  _passwordController, 
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  }, 
                  false
                ),
                
                const SizedBox(height: 12),
                
                _buildPasswordField(
                  "Confirmar Contraseña", 
                  _confirmPasswordController, 
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  }, 
                  true
                ),
                
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Iniciar Sesión", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8BC34A),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: _registerWithEmailAndPassword,
                              child: const Text(
                                "Crear Cuenta", 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text(
                  "Nota: Todos los usuarios se crean como 'Clientes' por defecto. "
                  "Los administradores deben ser asignados manualmente.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
