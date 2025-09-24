import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import '../services/auth_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  
  bool _mostrarTelefono = false;
  bool _modoEdicion = false;
  int _currentIndex = 3;
  bool _isLoading = false;
  bool _isLoadingData = true; // ✅ NUEVO: Para controlar carga inicial
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // ✅ CORREGIDO: Método mejorado para cargar datos
  Future<void> _cargarDatosUsuario() async {
    setState(() {
      _isLoadingData = true;
    });

    // Pequeña pausa para asegurar que el contexto esté listo
    await Future.delayed(const Duration(milliseconds: 100));
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      setState(() {
        nombreController.text = user.name;
        usuarioController.text = user.username ?? user.email.split('@').first;
        correoController.text = user.email;
        telefonoController.text = user.phone ?? '';
        _isLoadingData = false;
      });
    } else {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // ✅ CORREGIDO: Usar didChangeDependencies para recargar cuando cambie el contexto
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos si el usuario cambia
    final authService = Provider.of<AuthService>(context);
    if (authService.currentUser != null && !_isLoadingData) {
      _cargarDatosUsuario();
    }
  }

  Future<void> _guardarCambios() async {
    if (nombreController.text.isEmpty || 
        usuarioController.text.isEmpty || 
        telefonoController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final error = await authService.updateUserProfile(
        name: nombreController.text.trim(),
        phone: telefonoController.text.trim(),
        username: usuarioController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        if (error == null) {
          _modoEdicion = false;
          _errorMessage = null;
        } else {
          _errorMessage = error;
        }
      });

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados correctamente'), 
            backgroundColor: Color(0xFF8BC34A), 
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al guardar los cambios';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, Routes.catalogo);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.notification);
        break;
      case 3:
        // Ya estamos en perfil
        break;
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                Navigator.pushReplacementNamed(context, Routes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009CA8),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // ✅ MEJORADO: Manejo de estados de carga
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF009CA8),
          elevation: 0,
          title: const Text(
            'Perfil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          // ✅ CORREGIDO: Eliminado el icono de retroceso
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009CA8)),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando perfil...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No hay usuario logueado', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009CA8),
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009CA8),
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        // ✅ CORREGIDO: Eliminado el icono de retroceso
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con icono
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF009CA8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      user.role == 'admin' ? Icons.admin_panel_settings : Icons.person, 
                      size: 60,
                      color: const Color(0xFF009CA8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.name.isNotEmpty ? user.name : 'Mi Perfil',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '@${usuarioController.text.isNotEmpty ? usuarioController.text : user.email.split('@').first}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role == 'admin' ? 'Administrador' : 'Cliente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Mensaje de error
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),

            // Card con campos
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildCampo('Nombre', nombreController, Icons.person),
                  const SizedBox(height: 20),
                  _buildCampo('Usuario', usuarioController, Icons.badge),
                  const SizedBox(height: 20),
                  _buildCampo('Correo electrónico', correoController, Icons.email, editable: false),
                  const SizedBox(height: 20),
                  _buildCampoTelefono('Teléfono', telefonoController, Icons.phone),
                  const SizedBox(height: 30),
                  
                  _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _modoEdicion 
                          ? _buildBotonesEdicion() 
                          : _buildBotonModificar(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF009CA8),
        unselectedItemColor: const Color(0xFF9E9E9E),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: Color(0xFF009CA8)),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart, color: Color(0xFF009CA8)),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description, color: Color(0xFF009CA8)),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person, color: Color(0xFF009CA8)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildCampo(String titulo, TextEditingController controller, IconData icono, {bool editable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.black87
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _modoEdicion && editable ? Colors.white : Colors.grey[50],
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icono, color: const Color(0xFF009CA8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: _modoEdicion && editable
                      ? TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none, 
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 16),
                        )
                      : Text(
                          controller.text.isNotEmpty ? controller.text : 'No especificado',
                          style: TextStyle(
                            fontSize: 16, 
                            color: controller.text.isNotEmpty ? Colors.black87 : Colors.grey,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoTelefono(String titulo, TextEditingController controller, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo, 
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.black87
          )
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _modoEdicion ? Colors.white : Colors.grey[50],
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icono, color: const Color(0xFF009CA8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: _modoEdicion
                      ? TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none, 
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.phone,
                        )
                      : Text(
                          _mostrarTelefono && controller.text.isNotEmpty 
                            ? controller.text 
                            : controller.text.isNotEmpty ? '••••••••••' : 'No especificado',
                          style: TextStyle(
                            fontSize: 16, 
                            color: controller.text.isNotEmpty ? Colors.black87 : Colors.grey,
                          ),
                        ),
                ),
                if (!_modoEdicion && controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _mostrarTelefono ? Icons.visibility : Icons.visibility_off, 
                      color: const Color(0xFF009CA8), 
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarTelefono = !_mostrarTelefono;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonModificar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => setState(() => _modoEdicion = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009CA8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Modificar Perfil', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildBotonesEdicion() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _modoEdicion = false;
                _cargarDatosUsuario();
                _errorMessage = null;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF009CA8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Color(0xFF009CA8)),
            ),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    usuarioController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    super.dispose();
  }
}