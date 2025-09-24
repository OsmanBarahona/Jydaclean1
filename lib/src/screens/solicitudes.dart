import 'package:flutter/material.dart';
import '../services/orders_service.dart';
import '../services/notifications_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/products_service.dart'; // Para Product

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrdersService ordersService = OrdersService();
  final NotificationsService notificationsService = NotificationsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _productosAcumulados = [];
  bool _argumentosProcesados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _procesarArgumentos();
    });
  }

  void _procesarArgumentos() {
    if (_argumentosProcesados) return;

    final argumentos = ModalRoute.of(context)?.settings.arguments;
    if (argumentos == null) return;

    if (argumentos is List<Product>) {
      _agregarProductos(_normalizarProductos(argumentos));
    } else if (argumentos is List<Map<String, dynamic>>) {
      _agregarProductos(argumentos);
    } else if (argumentos is Product) {
      _agregarProductos(_normalizarProductos([argumentos]));
    } else if (argumentos is Map<String, dynamic>) {
      _agregarProductos([argumentos]);
    }

    _argumentosProcesados = true;
  }

  List<Map<String, dynamic>> _normalizarProductos(List<Product> items) {
    return items.map((p) => {
      'id': p.id,
      'title': p.name,
      'price': p.price,
      'image': p.imageUrl.isNotEmpty ? p.imageUrl : 'assets/images/logo/jydaclean.jpg',
      'quantity': 1,
      'type': p.type,
    }).toList();
  }

  void _agregarProductos(List<Map<String, dynamic>> nuevosProductos) {
    if (nuevosProductos.isEmpty) return;

    setState(() {
      for (var nuevoProducto in nuevosProductos) {
        if (nuevoProducto['title'] == null) continue;
        if (nuevoProducto['image'] != null && nuevoProducto['image'].startsWith('file://')) {
          nuevoProducto['image'] = nuevoProducto['image'].replaceFirst('file://', '');
        }
        if (nuevoProducto['id'] == null) {
          nuevoProducto['id'] = '${nuevoProducto['title']}_${DateTime.now().millisecondsSinceEpoch}';
        }

        final String id = nuevoProducto['id'].toString();
        final int existingIndex = _productosAcumulados.indexWhere(
          (existente) => existente['id']?.toString() == id
        );

        if (existingIndex != -1) {
          if (nuevoProducto['quantity'] != null) {
            _productosAcumulados[existingIndex]['quantity'] = nuevoProducto['quantity'];
          }
        } else {
          _productosAcumulados.add(Map<String, dynamic>.from(nuevoProducto));
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _realizarPedido() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor complete todos los campos obligatorios"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_productosAcumulados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay productos en el carrito"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final datosCliente = {
        "nombre": _nameController.text.trim(),
        "telefono": _phoneController.text.trim(),
        "direccion": _addressController.text.trim(),
        "instrucciones": _instructionController.text.trim(),
        "fecha": DateTime.now().toIso8601String(),
        "estado": "pendiente",
      };

      await ordersService.createOrder(
        productos: _productosAcumulados,
        datosCliente: datosCliente,
      );

      if (_auth.currentUser != null) {
        await notificationsService.createNotification(
          userId: _auth.currentUser!.uid,
          titulo: "Pedido realizado exitosamente",
          productos: _productosAcumulados,
          isPromotion: false,
        );
      }

      _limpiarCarrito();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pedido realizado correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al realizar pedido: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  double _calcularTotal() {
    double subtotal = 0.0;
    for (var producto in _productosAcumulados) {
      final precio = _parsePrecio(producto["price"]);
      final cantidad = producto["quantity"] ?? 1;
      subtotal += precio * cantidad;
    }
    final impuestos = subtotal * 0.15;
    return subtotal + impuestos;
  }

  double _parsePrecio(dynamic precio) {
    if (precio == null) return 0.0;
    if (precio is double) return precio;
    if (precio is int) return precio.toDouble();
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(precio.toString());
    return match != null ? double.tryParse(match.group(1)!) ?? 0.0 : 0.0;
  }

  void _limpiarCarrito() {
    setState(() {
      _productosAcumulados.clear();
      _argumentosProcesados = false;
    });
  }

  void _removerProducto(int index) {
    if (index >= 0 && index < _productosAcumulados.length) {
      final productoEliminado = _productosAcumulados[index];
      setState(() {
        _productosAcumulados.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${productoEliminado['title']} removido del carrito"),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _productosAcumulados.insert(index, productoEliminado);
              });
            },
          ),
        ),
      );
    }
  }

  Widget _loadImage(String imagePath) {
    if (imagePath.startsWith('file://')) imagePath = imagePath.replaceFirst('file://', '');
    if (imagePath.startsWith('assets/')) return Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.cover);
    if (imagePath.startsWith('http')) return Image.network(imagePath, width: 60, height: 60, fit: BoxFit.cover);
    return Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.shopping_cart));
  }

  Widget _buildProductItem(Map<String, dynamic> producto, int index) {
    final titulo = producto["title"] ?? "Producto sin nombre";
    final precio = producto["price"] ?? 0;
    final imagen = producto["image"] ?? 'assets/images/logo/jydaclean.jpg';
    final cantidad = producto["quantity"] ?? 1;
    final tipo = producto['type'] ?? 'product';
    final actionText = tipo == 'service' ? 'Contratar' : 'Solicitar';

    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _loadImage(imagen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("L. ${_parsePrecio(precio).toStringAsFixed(2)}", style: const TextStyle(color: Colors.amber)),
                  const SizedBox(height: 2),
                  Text("Cantidad: $cantidad • $actionText", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removerProducto(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    double subtotal = 0.0;
    for (var producto in _productosAcumulados) {
      subtotal += _parsePrecio(producto["price"]) * (producto["quantity"] ?? 1);
    }
    final impuestos = subtotal * 0.15;
    final total = subtotal + impuestos;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _buildTotalRow("Subtotal", "L. ${subtotal.toStringAsFixed(2)}"),
          _buildTotalRow("Impuestos (15%)", "L. ${impuestos.toStringAsFixed(2)}"),
          const Divider(color: Colors.white54),
          _buildTotalRow("TOTAL", "L. ${total.toStringAsFixed(2)}", bold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: bold ? Colors.amber : Colors.white, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres realizar este pedido?'),
            const SizedBox(height: 16),
            Text('Productos: ${_productosAcumulados.length}'),
            Text('Total: L. ${_calcularTotal().toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { Navigator.of(ctx).pop(); _realizarPedido(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF009CA8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009CA8),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Complete su información", style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(controller: _nameController, decoration: InputDecoration(hintText: "Nombre completo *", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.person))),
                        const SizedBox(height: 12),
                        TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: "Número de teléfono *", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.phone))),
                        const SizedBox(height: 12),
                        TextField(controller: _addressController, decoration: InputDecoration(hintText: "Dirección completa *", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.location_on))),
                        const SizedBox(height: 12),
                        TextField(controller: _instructionController, maxLines: 2, decoration: InputDecoration(hintText: "Instrucción especial (Opcional)", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.note))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF007C91),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("Productos seleccionados", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text("(${_productosAcumulados.length})", style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _productosAcumulados.isEmpty
                              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white54), const SizedBox(height: 16), const Text("No hay productos en el carrito", style: TextStyle(color: Colors.white70)), const SizedBox(height: 8), const Text("Agrega productos desde el catálogo", style: TextStyle(color: Colors.white54, fontSize: 12))]))
                              : Column(
                                  children: [
                                    Expanded(child: ListView.builder(itemCount: _productosAcumulados.length, itemBuilder: (context, index) => _buildProductItem(_productosAcumulados[index], index))),
                                    const SizedBox(height: 16),
                                    _buildTotalSection(),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF009CA8),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _productosAcumulados.isNotEmpty ? Colors.amber : Colors.grey,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: _productosAcumulados.isNotEmpty ? _mostrarDialogoConfirmacion : null,
                        child: _loading ? const CircularProgressIndicator(color: Colors.black) : Text(_productosAcumulados.isEmpty ? "Carrito vacío" : "Realizar Pedido (${_productosAcumulados.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
