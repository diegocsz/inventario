import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AuthDAO {
  AuthDAO(this.client);
  final SupabaseClient client;
  Stream<AuthState> get authChanges => client.auth.onAuthStateChange;
  User? get currentUser => client.auth.currentUser;
  Future<void> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);
  Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);
  Future<void> signOut() => client.auth.signOut();
  Future<void> updatePassword(String password) =>
      client.auth.updateUser(UserAttributes(password: password));
}

class PerfilDAO {
  PerfilDAO(this.client);
  final SupabaseClient client;
  Future<Perfil?> getCurrent() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await client
        .from('perfiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Perfil.fromMap(row);
  }

  Future<void> updateName(String nombres, String apellidos) async {
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      await client
          .from('perfiles')
          .update({'nombres': nombres, 'apellidos': apellidos})
          .eq('id', uid);
    }
  }
}

class CategoriaDAO {
  CategoriaDAO(this.client);
  final SupabaseClient client;
  Future<List<Categoria>> list() async {
    final rows = await client
        .from('categorias')
        .select()
        .eq('activo', true)
        .order('nombre');
    return rows.map<Categoria>((row) => Categoria.fromMap(row)).toList();
  }

  Future<void> create(String nombre, String? descripcion) async {
    final uid = client.auth.currentUser!.id;
    await client.from('categorias').insert({
      'nombre': nombre.trim(),
      'descripcion': descripcion?.trim(),
      'activo': true,
      'creado_por': uid,
    });
  }

  Future<void> update(
    Categoria categoria,
    String nombre,
    String? descripcion,
  ) => client
      .from('categorias')
      .update({'nombre': nombre.trim(), 'descripcion': descripcion?.trim()})
      .eq('id', categoria.id);
  Future<void> deactivate(String id) =>
      client.from('categorias').update({'activo': false}).eq('id', id);
}

class ProductoDAO {
  ProductoDAO(this.client);
  final SupabaseClient client;
  Future<List<Producto>> list() async {
    final rows = await client
        .from('productos')
        .select()
        .eq('activo', true)
        .order('nombre');
    return rows.map<Producto>((row) => Producto.fromMap(row)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    data['creado_por'] = client.auth.currentUser!.id;
    await client.from('productos').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) =>
      client.from('productos').update(data).eq('id', id);
  Future<void> deactivate(String id) =>
      client.from('productos').update({'activo': false}).eq('id', id);
}

class MovimientoDAO {
  MovimientoDAO(this.client);
  final SupabaseClient client;
  Future<List<Movimiento>> list({String? productoId, String? tipo}) async {
    var query = client.from('movimientos').select();
    if (productoId != null) query = query.eq('producto_id', productoId);
    if (tipo != null) query = query.eq('tipo', tipo);
    final rows = await query.order('creado_en', ascending: false).limit(200);
    return rows.map<Movimiento>((row) => Movimiento.fromMap(row)).toList();
  }

  Future<void> registrar({
    required String productoId,
    required String tipo,
    required int cantidad,
    String? motivo,
  }) async {
    await client.rpc(
      'registrar_movimiento',
      params: {
        'p_producto_id': productoId,
        'p_tipo': tipo,
        'p_cantidad': cantidad,
        'p_motivo': motivo,
      },
    );
  }
}
