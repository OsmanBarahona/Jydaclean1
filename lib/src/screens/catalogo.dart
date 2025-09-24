import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import '../services/products_service.dart';
import '../services/notifications_service.dart';
import '../services/orders_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String selectedCategory = 'Todos';
  String selectedType = 'Todos';
  String searchQuery = '';
  int _currentIndex = 1;

  List<Map<String, dynamic>> _productosSeleccionados = [];

  @override
  void initState() {
    super.initState();
  }

  void _onSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar Catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...['Todos', 'Productos', 'Servicios'].map((type) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(type),
                    trailing: selectedType == type
                        ? const Icon(Icons.check, color: Color(0xFF009CA8))
                        : null,
                    onTap: () {
                      setState(() {
                        selectedType = type;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
                const SizedBox(height: 20),
                const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...['Todos', 'Hogar', 'Comercial', 'Industrial', 'Residencial'].map((category) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(category),
                    trailing: selectedCategory == category
                        ? const Icon(Icons.check, color: Color(0xFF009CA8))
                        : null,
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.home);
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, Routes.notification);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, Routes.profile);
        break;
    }
  }

  Stream<List<Product>> _getFilteredStream(ProductsService service) {
    if (searchQuery.isNotEmpty) {
      return service.searchItems(searchQuery);
    }

    return service.getAllItems().asyncMap((allItems) {
      List<Product> filteredItems = allItems;

      if (selectedType == 'Productos') {
        filteredItems = filteredItems.where((item) => item.type == 'product').toList();
      } else if (selectedType == 'Servicios') {
        filteredItems = filteredItems.where((item) => item.type == 'service').toList();
      }

      if (selectedCategory != 'Todos') {
        filteredItems = filteredItems.where((item) => item.category == selectedCategory).toList();
      }

      return filteredItems;
    });
  }

  void _agregarProductoAlCarrito(Product product) {
    final notificationsService = NotificationsService();
    final currentUser = FirebaseAuth.instance.currentUser!;

    final productoCompleto = {
      'id': product.id,
      'nombre': product.name,
      'titulo': product.name,
      'descripcion': product.description,
      'precio': product.priceDisplay,
      'imagen': product.imageUrl ?? 'assets/images/logo/jydaclean.jpg',
      'tipo': product.type,
      'categoria': product.category,
      'duracion': product.duration,
      'incluye': product.includes,
      'stock': product.stock,
      'unidad': product.unit,
    };

    notificationsService.createNotification(
      userId: currentUser.uid,
      titulo: 'Solicitud de ${product.name}',
      productos: [productoCompleto],
    );

    setState(() {
      _productosSeleccionados.add(productoCompleto);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        backgroundColor: const Color(0xFF8BC34A),
      ),
    );
  }

  void _irAlCheckout() {
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega productos al carrito primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushNamed(context, Routes.solicitudes, arguments: _productosSeleccionados);
  }

  Future<void> _realizarPedido() async {
    if (_productosSeleccionados.isEmpty) return;

    try {
      final ordersService = OrdersService();
      final currentUser = FirebaseAuth.instance.currentUser!;
      await ordersService.createOrder(
        productos: _productosSeleccionados,
        datosCliente: {
          'nombre': currentUser.displayName ?? '',
          'email': currentUser.email ?? '',
          'uid': currentUser.uid,
        },
      );

      setState(() => _productosSeleccionados.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido realizado correctamente'),
          backgroundColor: Color(0xFF8BC34A),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarCarrito() {
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CarritoSheet(
        productos: _productosSeleccionados,
        onCheckout: _irAlCheckout,
        onRemove: (index) {
          setState(() {
            _productosSeleccionados.removeAt(index);
          });
          Navigator.of(context).pop();
          if (_productosSeleccionados.isNotEmpty) {
            _mostrarCarrito();
          }
        },
        onRealizarPedido: _realizarPedido,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  /// 🟢 Función segura para cargar imágenes
  Widget _loadImage(String? imageUrl, {double width = double.infinity, double height = double.infinity, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset('assets/images/logo/jydaclean.jpg', width: width, height: height, fit: fit);
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/logo/jydaclean.jpg', width: width, height: height, fit: fit),
      );
    }
    // Ruta local
    return Image.asset(imageUrl, width: width, height: height, fit: fit);
  }

  @override
  Widget build(BuildContext context) {
    final productsService = Provider.of<ProductsService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF009CA8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009CA8),
        elevation: 0,
        title: const Text('Catálogo'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart), onPressed: _mostrarCarrito),
              if (_productosSeleccionados.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      _productosSeleccionados.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar productos y servicios...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _getFilteredStream(productsService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.white70),
                        SizedBox(height: 16),
                        Text('No se encontraron items', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return _ProductServiceCard(
                      product: product,
                      onTap: () => _showItemDetails(context, product),
                      loadImage: _loadImage,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _productosSeleccionados.isNotEmpty
          ? FloatingActionButton(
              onPressed: _irAlCheckout,
              backgroundColor: const Color(0xFF8BC34A),
              child: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF009CA8),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8BC34A),
        unselectedItemColor: Colors.white70,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Catálogo"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Solicitudes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ItemDetailSheet(
        product: product,
        onOrder: () {
          _agregarProductoAlCarrito(product);
          Navigator.of(context).pop();
        },
        loadImage: _loadImage,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}

/// 🟢 Widget de tarjeta de producto/servicio
class _ProductServiceCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final Widget Function(String?, {double width, double height, BoxFit fit}) loadImage;

  const _ProductServiceCard({required this.product, required this.onTap, required this.loadImage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: loadImage(product.imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(product.priceDisplay, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🟢 Widget de detalle de producto/servicio
class _ItemDetailSheet extends StatelessWidget {
  final Product product;
  final VoidCallback onOrder;
  final Widget Function(String?, {double width, double height, BoxFit fit}) loadImage;

  const _ItemDetailSheet({required this.product, required this.onOrder, required this.loadImage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Center(
                child: loadImage(product.imageUrl, width: 150, height: 150),
              ),
              const SizedBox(height: 16),
              Text(product.description),
              const SizedBox(height: 8),
              Text('Precio: ${product.priceDisplay}'),
              const SizedBox(height: 8),
              Text('Tipo: ${product.type}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BC34A)),
                  child: Text(product.type == 'service' ? 'Contratar' : 'Solicitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🟢 Widget de carrito
class _CarritoSheet extends StatelessWidget {
  final List<Map<String, dynamic>> productos;
  final VoidCallback onCheckout;
  final Function(int) onRemove;
  final VoidCallback onRealizarPedido;

  const _CarritoSheet({
    required this.productos,
    required this.onCheckout,
    required this.onRemove,
    required this.onRealizarPedido,
  });

  @override
  Widget build(BuildContext context) {
    Widget _loadImage(String? imageUrl, {double width = 40, double height = 40, BoxFit fit = BoxFit.cover}) {
      if (imageUrl == null || imageUrl.isEmpty) {
        return Image.asset('assets/images/logo/jydaclean.jpg', width: width, height: height, fit: fit);
      }
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Image.asset('assets/images/logo/jydaclean.jpg', width: width, height: height, fit: fit),
        );
      }
      return Image.asset(imageUrl, width: width, height: height, fit: fit);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Carrito de Compras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: ClipOval(
                      child: _loadImage(producto['imagen'], width: 40, height: 40),
                    ),
                  ),
                  title: Text(producto['nombre']),
                  subtitle: Text(producto['precio']),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onRemove(index)),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('Total: ${productos.length} producto(s)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Seguir comprando'))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCheckout();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8BC34A)),
                  child: const Text('Checkout'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRealizarPedido();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Realizar Pedido'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


