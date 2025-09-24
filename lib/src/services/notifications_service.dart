import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsService {
  final CollectionReference notificationsRef =
      FirebaseFirestore.instance.collection("notifications");

  /// 🔹 CREAR NOTIFICACIÓN CON DATOS COMPLETOS DEL PRODUCTO/SERVICIO
  Future<void> createNotification({
    required String userId,
    required String titulo,
    required List<Map<String, dynamic>> productos, // ✅ Objetos completos
    bool isPromotion = false,
  }) async {
    await notificationsRef.add({
      "userId": userId,
      "titulo": titulo,
      "fecha": FieldValue.serverTimestamp(),
      "productos": productos, // ✅ Datos completos, no solo nombres
      "isPromotion": isPromotion,
      "productosCompletos": true, // ✅ Marcar que tiene datos completos
    });
  }

  /// 🔹 MÉTODO PARA COMPATIBILIDAD: Notificación solo con nombres
  Future<void> createSimpleNotification({
    required String userId,
    required String titulo,
    required List<String> productosNombres,
    bool isPromotion = false,
  }) async {
    final productos = productosNombres.map((nombre) => {
      'nombre': nombre,
      'titulo': nombre,
    }).toList();

    await notificationsRef.add({
      "userId": userId,
      "titulo": titulo,
      "fecha": FieldValue.serverTimestamp(),
      "productos": productos,
      "isPromotion": isPromotion,
      "productosCompletos": false, // ✅ Datos básicos
    });
  }

  /// 🔹 OBTENER NOTIFICACIONES DEL USUARIO
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return notificationsRef
        .where("userId", isEqualTo: userId)
        .orderBy("fecha", descending: true)
        .snapshots();
  }

  /// 🔹 OBTENER SOLO SOLICITUDES
  Stream<QuerySnapshot> getUserSolicitudes(String userId) {
    return notificationsRef
        .where("userId", isEqualTo: userId)
        .where("isPromotion", isEqualTo: false)
        .orderBy("fecha", descending: true)
        .snapshots();
  }

  /// 🔹 OBTENER SOLO PROMOCIONES
  Stream<QuerySnapshot> getUserPromociones(String userId) {
    return notificationsRef
        .where("userId", isEqualTo: userId)
        .where("isPromotion", isEqualTo: true)
        .orderBy("fecha", descending: true)
        .snapshots();
  }
}
