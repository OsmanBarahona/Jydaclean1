import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String priceDisplay;
  final String category;
  final String imageUrl;
  final String type; // 'product' o 'service'
  final bool isFeatured;
  final int orderCount;
  final int? stock; // Solo para productos
  final String? unit; // Solo para productos
  final String? duration; // Solo para servicios
  final List<String>? includes; // Solo para servicios

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceDisplay,
    required this.category,
    required this.imageUrl,
    required this.type,
    required this.isFeatured,
    required this.orderCount,
    this.stock,
    this.unit,
    this.duration,
    this.includes,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      priceDisplay: data['priceDisplay'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'product',
      isFeatured: data['isFeatured'] ?? false,
      orderCount: data['orderCount'] ?? 0,
      stock: data['stock'],
      unit: data['unit'],
      duration: data['duration'],
      includes: data['includes'] != null ? List<String>.from(data['includes']) : null,
    );
  }

  // Método para mostrar información específica según el tipo
  String get displayInfo {
    if (type == 'service') {
      return duration ?? 'Servicio';
    } else {
      return unit ?? 'Producto';
    }
  }

  // Método para el botón según el tipo
  String get actionButtonText {
    return type == 'service' ? 'Contratar' : 'Solicitar';
  }
}

class ProductsService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 1. Obtener productos destacados (para HOME - solo productos)
  Stream<List<Product>> getFeaturedProducts() {
    return _firestore
        .collection('Products')
        .where('isFeatured', isEqualTo: true)
        .where('type', isEqualTo: 'product')
        .orderBy('orderCount', descending: true)
        .limit(6)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // 2. Obtener servicios destacados (para HOME - solo servicios)
  Stream<List<Product>> getFeaturedServices() {
    return _firestore
        .collection('Services')
        .where('isFeatured', isEqualTo: true)
        .where('type', isEqualTo: 'service')
        .orderBy('orderCount', descending: true)
        .limit(6)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // 3. Obtener TODOS los items (productos + servicios para CATÁLOGO)
  Stream<List<Product>> getAllItems() {
    // Necesitamos combinar streams de ambas colecciones
    return _firestore
        .collection('Products')
        .orderBy('name')
        .snapshots()
        .asyncMap((productsSnapshot) async {
          final servicesSnapshot = await _firestore
              .collection('Services')
              .orderBy('name')
              .get();
          
          final allItems = [
            ...productsSnapshot.docs.map((doc) => Product.fromFirestore(doc)),
            ...servicesSnapshot.docs.map((doc) => Product.fromFirestore(doc)),
          ];
          
          // Ordenar por nombre
          allItems.sort((a, b) => a.name.compareTo(b.name));
          return allItems;
        });
  }

  // 4. Buscar items por nombre o descripción
  Stream<List<Product>> searchItems(String query) {
    return _firestore
        .collection('Products')
        .orderBy('name')
        .snapshots()
        .asyncMap((productsSnapshot) async {
          final servicesSnapshot = await _firestore
              .collection('Services')
              .orderBy('name')
              .get();
          
          final allItems = [
            ...productsSnapshot.docs.map((doc) => Product.fromFirestore(doc)),
            ...servicesSnapshot.docs.map((doc) => Product.fromFirestore(doc)),
          ];
          
          return allItems.where((item) => 
            item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.description.toLowerCase().contains(query.toLowerCase())
          ).toList();
        });
  }

  // 5. Filtrar por categoría y tipo
  Stream<List<Product>> getItemsByCategoryAndType(String category, String type) {
    String collection = type == 'service' ? 'Services' : 'Products';
    
    if (category == 'Todos') {
      return _firestore
          .collection(collection)
          .where('type', isEqualTo: type)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList());
    }
    
    return _firestore
        .collection(collection)
        .where('category', isEqualTo: category)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // 6. Obtener solo productos
  Stream<List<Product>> getProductsOnly() {
    return _firestore
        .collection('Products')
        .where('type', isEqualTo: 'product')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // 7. Obtener solo servicios
  Stream<List<Product>> getServicesOnly() {
    return _firestore
        .collection('Services')
        .where('type', isEqualTo: 'service')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // 8. Incrementar contador de pedidos
  Future<void> incrementOrderCount(String itemId, String type) async {
    try {
      String collection = type == 'service' ? 'Services' : 'Products';
      await _firestore.collection(collection).doc(itemId).update({
        'orderCount': FieldValue.increment(1),
        'lastOrdered': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing order count: $e');
      }
    }
  }
}