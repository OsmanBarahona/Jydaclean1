import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import '../services/products_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userRole = 'client';
  String _userName = 'Usuario';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc['role'] ?? 'client';
            _userName = userDoc['name'] ?? 'Usuario';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _userRole = 'client';
        _isLoading = false;
      });
    }
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        break; // Ya estamos en Home
      case 1:
        Navigator.pushReplacementNamed(context, Routes.catalogo);
        break;
      case 2:
        if (_userRole == 'admin') {
          Navigator.pushReplacementNamed(context, Routes.gestiondepedidos);
        } else {
          Navigator.pushReplacementNamed(context, Routes.notification);
        }
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.profile);
        break;
    }
  }

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      Navigator.pushNamed(context, Routes.catalogo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFE6F0F2),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009CA8),
        elevation: 0,
        title: Text(
          _userRole == 'admin' ? 'Panel Administrador' : 'JYDACLEAN',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_userRole == 'admin')
            IconButton(
              onPressed: () => Navigator.pushNamed(context, Routes.gestiondepedidos),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              tooltip: 'Gestión de Pedidos',
            ),
          // ✅ ICONO DE CERRAR SESIÓN
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Diálogo de confirmación
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
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header simplificado
            SliverToBoxAdapter(
              child: _HomeHeader(userName: _userName, userRole: _userRole),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Banner promocional
            SliverToBoxAdapter(child: _PromoBanner()),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Barra de búsqueda funcional
            SliverToBoxAdapter(
              child: _SearchBar(onSearch: _handleSearch),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Categorías como navegación rápida
            SliverToBoxAdapter(
              child: _CategoriesSection(onCategoryTap: (category) {
                Navigator.pushNamed(context, Routes.catalogo);
              }),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Productos destacados desde Firestore
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Productos Destacados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: _FeaturedProductsSection(),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Servicios destacados desde Firestore
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Servicios Destacados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: _FeaturedServicesSection(),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        userRole: _userRole,
        onTap: _navigateToScreen,
      ),
    );
  }
}

// Header simplificado - SIN botón de notificaciones redundante
class _HomeHeader extends StatelessWidget {
  final String userName;
  final String userRole;
  
  const _HomeHeader({required this.userName, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: userRole == 'admin' ? Colors.orange : const Color(0xFF009CA8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              userRole == 'admin' ? Icons.admin_panel_settings : Icons.cleaning_services,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $userName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  userRole == 'admin' ? 'Cuenta Administrador' : 'Bienvenido de vuelta',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Banner promocional mejorado
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF009CA8), Color(0xFF00BCD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OFERTA ESPECIAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '20% DCTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'En productos seleccionados',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF009CA8),
                  ),
                  onPressed: () => Navigator.pushNamed(context, Routes.catalogo),
                  child: const Text('Ver Ofertas'),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_offer, size: 64, color: Colors.white30),
        ],
      ),
    );
  }
}

// Barra de búsqueda funcional
class _SearchBar extends StatelessWidget {
  final Function(String) onSearch;
  
  const _SearchBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onSubmitted: onSearch,
        decoration: InputDecoration(
          hintText: 'Buscar productos y servicios...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// Categorías como navegación rápida
class _CategoriesSection extends StatelessWidget {
  final Function(String) onCategoryTap;
  
  const _CategoriesSection({required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': Icons.home, 'label': 'Hogar', 'color': Color(0xFF009CA8)},
      {'icon': Icons.business, 'label': 'Empresas', 'color': Color(0xFF8BC34A)},
      {'icon': Icons.factory, 'label': 'Industrial', 'color': Color(0xFFFF9800)},
      {'icon': Icons.cleaning_services, 'label': 'Servicios', 'color': Color(0xFFE91E63)},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => onCategoryTap(category['label'] as String),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category['icon'] as IconData, 
                      size: 32, color: category['color'] as Color),
                  const SizedBox(height: 8),
                  Text(category['label'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Productos destacados desde Firestore
class _FeaturedProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productsService = Provider.of<ProductsService>(context);
    
    return StreamBuilder<List<Product>>(
      stream: productsService.getFeaturedProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 120,
            child: Center(child: Text('Error al cargar productos')),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No hay productos destacados'),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductItemCard(product: product);
            },
          ),
        );
      },
    );
  }
}

// Servicios destacados desde Firestore
class _FeaturedServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productsService = Provider.of<ProductsService>(context);
    
    return StreamBuilder<List<Product>>(
      stream: productsService.getFeaturedServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 120,
            child: Center(child: Text('Error al cargar servicios')),
          );
        }

        final services = snapshot.data ?? [];

        if (services.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cleaning_services, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No hay servicios destacados'),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _ServiceItemCard(service: service);
            },
          ),
        );
      },
    );
  }
}

// Tarjeta de producto
class _ProductItemCard extends StatelessWidget {
  final Product product;

  const _ProductItemCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF009CA8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_drink, size: 40, color: Color(0xFF009CA8)),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.priceDisplay,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {},
                  child: const Text('Ver', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta de servicio
class _ServiceItemCard extends StatelessWidget {
  final Product service;

  const _ServiceItemCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del servicio
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cleaning_services, size: 40, color: Color(0xFFFF9800)),
              ),
              const SizedBox(height: 8),
              Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                service.priceDisplay,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {},
                  child: const Text('Contratar', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Navigation Bar optimizado
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String userRole;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.userRole,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF009CA8),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Inicio",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: "Catálogo",
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment),
          label: userRole == 'admin' ? "Gestionar" : "Solicitudes",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Perfil",
        ),
      ],
    );
  }
}