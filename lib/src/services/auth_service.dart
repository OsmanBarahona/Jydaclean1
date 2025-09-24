import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? username; // Nuevo campo que necesitamos

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.username,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'client',
      username: data['username'], // Puede ser null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'username': username,
    };
  }
}

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserData? _currentUser;

  UserData? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      await _loadUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _currentUser = UserData.fromFirestore(userDoc);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  // Actualizar datos del usuario (para el perfil)
  Future<String?> updateUserProfile({
    required String name,
    required String phone,
    required String username,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 'Usuario no autenticado';

      final updatedData = {
        'name': name,
        'phone': phone,
        'username': username, // Agregar el campo username
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(currentUser.uid).update(updatedData);
      
      // Actualizar usuario local
      if (_currentUser != null) {
        _currentUser = UserData(
          uid: _currentUser!.uid,
          name: name,
          email: _currentUser!.email,
          phone: phone,
          role: _currentUser!.role,
          username: username,
        );
      }
      
      notifyListeners();
      return null; // Éxito
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      return 'Error al actualizar datos';
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}