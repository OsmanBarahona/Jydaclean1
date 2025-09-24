import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersService {
  final CollectionReference ordersRef =
      FirebaseFirestore.instance.collection("orders");

  // Crear un nuevo pedido
  Future<void> createOrder({
    required List<Map<String, dynamic>> productos,
    required Map<String, String> datosCliente,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    await ordersRef.add({
      "userId": user.uid,
      "productos": productos,
      "datosCliente": datosCliente,
      "estado": "pendiente",
      "fecha": FieldValue.serverTimestamp(),
    });
  }

  // Opcional: obtener pedidos del usuario
  Stream<QuerySnapshot> getUserOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    return ordersRef
        .where("userId", isEqualTo: user.uid)
        .orderBy("fecha", descending: true)
        .snapshots();
  }
}
