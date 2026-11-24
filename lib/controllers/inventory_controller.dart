import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/daos.dart';
import '../models/models.dart';

class InventoryController extends ChangeNotifier {
  InventoryController(this.client)
    : auth = AuthDAO(client),
      perfiles = PerfilDAO(client),
      categorias = CategoriaDAO(client),
      productos = ProductoDAO(client),
      movimientos = MovimientoDAO(client);
  final SupabaseClient client;
  final AuthDAO auth;
  final PerfilDAO perfiles;
  final CategoriaDAO categorias;
  final ProductoDAO productos;
  final MovimientoDAO movimientos;

  Perfil? perfil;
  List<Categoria> listaCategorias = [];
  List<Producto> listaProductos = [];
  List<Movimiento> listaMovimientos = [];
  bool loading = false;
  String? error;
  StreamSubscription<AuthState>? _authSubscription;

  void listenAuth() {
    _authSubscription ??= auth.authChanges.listen((_) async {
      if (auth.currentUser == null) {
        perfil = null;
        clear();
        notifyListeners();
      }
    });
  }

  void clear() {
    listaCategorias = [];
    listaProductos = [];
    listaMovimientos = [];
  }

  Future<bool> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      perfil = await perfiles.getCurrent();
      if (perfil == null) {
        error = 'Tu usuario no tiene un perfil asociado.';
        return false;
      }
      if (!perfil!.activo) {
        error = 'Tu perfil está inactivo.';
        return false;
      }
      await refreshAll();
      return true;
    } catch (e) {
      error = 'No fue posible cargar tu perfil. ${_message(e)}';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshCategories(),
      refreshProducts(),
      refreshMovements(),
    ]);
  }

  Future<void> refreshCategories() async {
    listaCategorias = await categorias.list();
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    listaProductos = await productos.list();
    notifyListeners();
  }

  Future<void> refreshMovements() async {
    listaMovimientos = await movimientos.list();
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    perfil = null;
    clear();
    notifyListeners();
  }

  Future<String?> createCategory(String nombre, String? descripcion) async {
    try {
      await categorias.create(nombre, descripcion);
      await refreshCategories();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> updateCategory(
    Categoria value,
    String nombre,
    String? descripcion,
  ) async {
    try {
      await categorias.update(value, nombre, descripcion);
      await refreshCategories();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> deactivateCategory(String id) async {
    try {
      await categorias.deactivate(id);
      await refreshCategories();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> createProduct(Map<String, dynamic> data) async {
    try {
      await productos.create(data);
      await refreshProducts();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await productos.update(id, data);
      await refreshProducts();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> deactivateProduct(String id) async {
    try {
      await productos.deactivate(id);
      await refreshProducts();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> movement({
    required String productoId,
    required String tipo,
    required int cantidad,
    String? motivo,
  }) async {
    try {
      await movimientos.registrar(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
      );
      await Future.wait([refreshProducts(), refreshMovements()]);
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  String _message(Object e) {
    if (e is PostgrestException) return e.message;
    if (e is AuthException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
