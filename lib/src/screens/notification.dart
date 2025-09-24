import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notifications_service.dart';
import '../services/auth_service.dart';
import 'routes.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  String timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Nuevo método: mostrar detalles de la notificación
  void _mostrarDetallesNotificacion(BuildContext context, Map<String, dynamic> data) {
    final productosData = data['productos'];
    List<String> productosNombres = [];

    if (productosData is List<String>) {
      productosNombres = productosData;
    } else if (productosData is List<dynamic>) {
      productosNombres = productosData.map<String>((p) {
        if (p is Map<String, dynamic>) {
          return p['nombre'] ?? p['titulo'] ?? 'Producto';
        }
        return p.toString();
      }).toList();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['titulo'] ?? 'Notificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (productosNombres.isNotEmpty) ...[
              const Text('Productos/Servicios incluidos:'),
              const SizedBox(height: 8),
              ...productosNombres.map((p) => Text('• $p')).toList(),
              const SizedBox(height: 8),
            ],
            Text('Fecha: ${timeAgo(data['fecha'] as Timestamp?)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, Routes.catalogo, (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, Routes.solicitudes, (route) => false);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, Routes.profile, (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsService = NotificationsService();
    final currentUser = FirebaseAuth.instance.currentUser!;
    final authService = AuthService();
    final int _currentIndex = 2;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F4),
        appBar: AppBar(
          backgroundColor: const Color(0xFF009CA8),
          automaticallyImplyLeading: false,
          title: const Text(
            "Notificaciones",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
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
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Solicitudes"),
              Tab(text: "Promociones"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: notificationsService.getUserNotifications(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No hay notificaciones.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            final solicitudes = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isPromotion = data['isPromotion'] as bool? ?? false;
              return !isPromotion;
            }).toList();

            final promociones = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isPromotion = data['isPromotion'] as bool? ?? false;
              return isPromotion;
            }).toList();

            return TabBarView(
              children: [
                solicitudes.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay solicitudes pendientes.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: solicitudes.length,
                        itemBuilder: (context, index) {
                          final notif = solicitudes[index];
                          final data = notif.data() as Map<String, dynamic>;

                          return InkWell(
                            onTap: () => _mostrarDetallesNotificacion(context, data),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/images/logo/jydaclean.jpg',
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['titulo'] ?? 'Sin título',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            timeAgo(data['fecha'] as Timestamp?),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                promociones.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay promociones disponibles.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: promociones.length,
                        itemBuilder: (context, index) {
                          final promo = promociones[index];
                          final data = promo.data() as Map<String, dynamic>;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo/jydaclean.jpg',
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['titulo'] ?? 'Sin título',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        timeAgo(data['fecha'] as Timestamp?),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF009CA8),
          unselectedItemColor: const Color(0xFF9E9E9E),
          onTap: (index) => _onItemTapped(context, index),
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
      ),
    );
  }
}
