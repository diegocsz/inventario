class Perfil {
  const Perfil({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    required this.activo,
  });
  final String id;
  final String nombres;
  final String apellidos;
  final String rol;
  final bool activo;
  bool get puedeEditar => activo && (rol == 'admin' || rol == 'editor');
  factory Perfil.fromMap(Map<String, dynamic> map) => Perfil(
    id: map['id'] as String,
    nombres: (map['nombres'] ?? '') as String,
    apellidos: (map['apellidos'] ?? '') as String,
    rol: (map['rol'] ?? 'viewer') as String,
    activo: map['activo'] == true,
  );
}

class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;
  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
    id: map['id'] as String,
    nombre: map['nombre'] as String,
    descripcion: map['descripcion'] as String?,
    activo: map['activo'] == true,
  );
}

class Producto {
  const Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    this.codigo,
    this.descripcion,
    required this.unidad,
    this.precio,
    required this.stock,
    required this.stockMinimo,
    required this.activo,
  });
  final String id;
  final String categoriaId;
  final String nombre;
  final String? codigo;
  final String? descripcion;
  final String unidad;
  final double? precio;
  final int stock;
  final int stockMinimo;
  final bool activo;
  String get estado {
    if (stock == 0 || stock <= 0) return 'CRITICO';
    if (stock <= stockMinimo) return 'BAJO';
    return 'NORMAL';
  }

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
    id: map['id'] as String,
    categoriaId: map['categoria_id'] as String,
    nombre: map['nombre'] as String,
    codigo: map['codigo'] as String?,
    descripcion: map['descripcion'] as String?,
    unidad: (map['unidad'] ?? 'unidad') as String,
    precio: map['precio'] == null
        ? null
        : double.tryParse(map['precio'].toString()),
    stock: (map['stock'] as num).toInt(),
    stockMinimo: (map['stock_minimo'] as num).toInt(),
    activo: map['activo'] == true,
  );
}

class Movimiento {
  const Movimiento({
    required this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockResultante,
    this.motivo,
    required this.creadoEn,
  });
  final String id;
  final String productoId;
  final String tipo;
  final int cantidad;
  final int stockAnterior;
  final int stockResultante;
  final String? motivo;
  final DateTime creadoEn;
  factory Movimiento.fromMap(Map<String, dynamic> map) => Movimiento(
    id: map['id'] as String,
    productoId: map['producto_id'] as String,
    tipo: map['tipo'] as String,
    cantidad: (map['cantidad'] as num).toInt(),
    stockAnterior: (map['stock_anterior'] as num).toInt(),
    stockResultante: (map['stock_resultante'] as num).toInt(),
    motivo: map['motivo'] as String?,
    creadoEn: DateTime.parse(map['creado_en'] as String),
  );
}
