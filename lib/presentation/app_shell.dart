import 'package:flutter/material.dart';

import '../controllers/inventory_controller.dart';
import '../models/models.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final InventoryController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pages = [
      HomePage(c: c),
      ProductsPage(c: c),
      CategoriesPage(c: c),
      MovementsPage(c: c),
      ProfilePage(c: c),
    ];
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) => IndexedStack(index: index, children: pages),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.c});
  final InventoryController c;
  @override
  Widget build(BuildContext context) {
    final critical = c.listaProductos
        .where((p) => p.estado == 'CRITICO')
        .length;
    final low = c.listaProductos.where((p) => p.estado == 'BAJO').length;
    final normal = c.listaProductos.where((p) => p.estado == 'NORMAL').length;
    return RefreshIndicator(
      onRefresh: c.refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'GESTIÓN INTELIGENTE',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Tu inventario',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              metric(
                'Productos',
                c.listaProductos.length,
                Icons.inventory_2,
                Colors.green,
              ),
              metric('Crítico', critical, Icons.warning_amber, Colors.red),
              metric('Stock bajo', low, Icons.priority_high, Colors.orange),
              metric('Normal', normal, Icons.check_circle, Colors.green),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Últimos movimientos',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (c.listaMovimientos.isEmpty)
            const Card(child: ListTile(title: Text('Aún no hay movimientos')))
          else
            ...c.listaMovimientos
                .take(5)
                .map(
                  (m) => Card(
                    child: ListTile(
                      leading: Icon(
                        m.tipo == 'ENTRADA'
                            ? Icons.add_circle
                            : Icons.remove_circle,
                        color: m.tipo == 'ENTRADA' ? Colors.green : Colors.red,
                      ),
                      title: Text('${m.tipo} · ${m.cantidad} unidades'),
                      subtitle: Text(m.motivo ?? 'Sin motivo'),
                      trailing: Text(
                        '${m.stockAnterior} → ${m.stockResultante}',
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget metric(String title, int value, IconData icon, Color color) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            '$value',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(title),
        ],
      ),
    ),
  );
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.c});
  final InventoryController c;
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String search = '';
  String category = '';
  String stock = 'TODOS';
  @override
  Widget build(BuildContext context) {
    var products =
        widget.c.listaProductos.where((p) {
          final nameMatch =
              p.nombre.toLowerCase().contains(search.toLowerCase().trim()) ||
              (p.codigo ?? '').toLowerCase().contains(
                search.toLowerCase().trim(),
              );
          final categoryMatch = category.isEmpty || p.categoriaId == category;
          final stockMatch =
              stock == 'TODOS' ||
              (stock == 'CRITICO' && p.estado == 'CRITICO') ||
              (stock == 'BAJO' && p.estado == 'BAJO') ||
              (stock == 'NORMAL' && p.estado == 'NORMAL');
          return nameMatch && categoryMatch && stockMatch;
        }).toList()..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
    return RefreshIndicator(
      onRefresh: widget.c.refreshAll,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => openProduct(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => search = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas')),
                      ...widget.c.listaCategorias.map(
                        (x) => DropdownMenuItem(
                          value: x.id,
                          child: Text(x.nombre),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => category = v ?? ''),
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No hay productos')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (_, i) => ProductCard(
                  c: widget.c,
                  product: products[i],
                  categoryName: widget.c.listaCategorias
                      .where((x) => x.id == products[i].categoriaId)
                      .firstOrNull
                      ?.nombre,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> openProduct(BuildContext context, [Producto? product]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductForm(c: widget.c, product: product),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.c,
    required this.product,
    this.categoryName,
  });
  final InventoryController c;
  final Producto product;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final critical = product.estado == 'CRITICO';
    final low = product.estado == 'BAJO';
    final background = critical
        ? const Color(0xffffebee)
        : low
        ? const Color(0xfffff4df)
        : const Color(0xffedf8ef);
    final color = critical
        ? Colors.red.shade700
        : low
        ? Colors.orange.shade800
        : Colors.green.shade700;
    final label = critical
        ? 'STOCK CRÍTICO'
        : low
        ? 'STOCK BAJO'
        : 'STOCK NORMAL';
    final icon = critical
        ? Icons.warning_amber
        : low
        ? Icons.priority_high
        : Icons.check_circle;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              width: double.infinity,
              child: const _ReservedProductImageArea(),
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    product.codigo ?? 'Sin código',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    categoryName ?? 'Sin categoría',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${product.stock} ${product.unidad} · Mín. ${product.stockMinimo}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => openMovement(context),
                        icon: const Icon(Icons.swap_vert),
                        tooltip: 'Movimiento',
                      ),
                      IconButton(
                        onPressed: () => openEdit(context),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openEdit(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductForm(c: c, product: product),
    );
  }

  Future<void> openMovement(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MovementForm(c: c, product: product),
    );
  }
}

class _ReservedProductImageArea extends StatelessWidget {
  const _ReservedProductImageArea();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xffedf8ef));
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key, required this.c});
  final InventoryController c;

  Future<void> openCategory(BuildContext context, [Categoria? category]) async {
    final name = TextEditingController(text: category?.nombre);
    final description = TextEditingController(text: category?.descripcion);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final error = category == null
                  ? await c.createCategory(name.text, description.text)
                  : await c.updateCategory(
                      category,
                      name.text,
                      description.text,
                    );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: c.refreshCategories,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Categorías',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: c.perfil?.puedeEditar == true
                    ? () => openCategory(context)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Nueva'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (c.listaCategorias.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No hay categorías')),
              ),
            )
          else
            ...c.listaCategorias.map(
              (category) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.category_outlined),
                  ),
                  title: Text(category.nombre),
                  subtitle: Text(category.descripcion ?? 'Sin descripción'),
                  trailing: c.perfil?.puedeEditar == true
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit')
                              await openCategory(context, category);
                            if (value == 'off') {
                              final error = await c.deactivateCategory(
                                category.id,
                              );
                              if (error != null && context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'off',
                              child: Text('Desactivar'),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MovementsPage extends StatelessWidget {
  const MovementsPage({super.key, required this.c});
  final InventoryController c;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: c.refreshMovements,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Movimientos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => MovementForm(c: c),
                ),
                icon: const Icon(Icons.swap_vert),
                label: const Text('Registrar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (c.listaMovimientos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aún no hay movimientos')),
              ),
            )
          else
            ...c.listaMovimientos.map((m) {
              final product = c.listaProductos
                  .where((p) => p.id == m.productoId)
                  .firstOrNull;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m.tipo == 'ENTRADA'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Icon(
                      m.tipo == 'ENTRADA' ? Icons.add : Icons.remove,
                      color: m.tipo == 'ENTRADA' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(product?.nombre ?? 'Producto'),
                  subtitle: Text(
                    '${m.tipo} · ${m.cantidad} · ${m.motivo ?? 'Sin motivo'}',
                  ),
                  trailing: Text(
                    '${m.stockAnterior} → ${m.stockResultante}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.c});
  final InventoryController c;
  @override
  Widget build(BuildContext context) {
    final user = c.auth.currentUser;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Perfil y configuración',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.email ?? 'Usuario'),
            subtitle: Text('Rol: ${c.perfil?.rol ?? ''}'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: const ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Conexión Supabase'),
            subtitle: Text('Autenticación y RLS activos'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: c.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
        ),
      ],
    );
  }
}

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, required this.c, this.product});
  final InventoryController c;
  final Producto? product;
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final code = TextEditingController();
  final description = TextEditingController();
  final unit = TextEditingController(text: 'unidad');
  final price = TextEditingController();
  final stock = TextEditingController(text: '0');
  final minimum = TextEditingController(text: '0');
  String? categoryId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      name.text = p.nombre;
      code.text = p.codigo ?? '';
      description.text = p.descripcion ?? '';
      unit.text = p.unidad;
      price.text = p.precio?.toStringAsFixed(2) ?? '';
      stock.text = p.stock.toString();
      minimum.text = p.stockMinimo.toString();
      categoryId = p.categoriaId;
    }
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    description.dispose();
    unit.dispose();
    price.dispose();
    stock.dispose();
    minimum.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }
    setState(() => saving = true);
    final data = <String, dynamic>{
      'categoria_id': categoryId,
      'codigo': code.text.trim().isEmpty ? null : code.text.trim(),
      'nombre': name.text.trim(),
      'descripcion': description.text.trim().isEmpty
          ? null
          : description.text.trim(),
      'unidad': unit.text.trim().isEmpty ? 'unidad' : unit.text.trim(),
      'precio': price.text.trim().isEmpty
          ? null
          : double.tryParse(price.text.trim()),
      'stock_minimo': int.tryParse(minimum.text) ?? 0,
    };
    if (widget.product == null) data['stock'] = int.tryParse(stock.text) ?? 0;
    final error = widget.product == null
        ? await widget.c.createProduct(data)
        : await widget.c.updateProduct(widget.product!.id, data);
    if (!mounted) return;
    setState(() => saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.94,
        maxChildSize: 0.96,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p == null ? 'Nuevo producto' : 'Editar producto',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el nombre'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Código o SKU'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: widget.c.listaCategorias
                      .map(
                        (x) => DropdownMenuItem(
                          value: x.id,
                          child: Text(x.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: unit,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (p == null)
                      Expanded(
                        child: TextFormField(
                          controller: stock,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock inicial',
                          ),
                          validator: (v) =>
                              int.tryParse(v ?? '') == null || int.parse(v!) < 0
                              ? 'Stock inválido'
                              : null,
                        ),
                      ),
                    if (p == null) const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: minimum,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock mínimo',
                        ),
                        validator: (v) =>
                            int.tryParse(v ?? '') == null || int.parse(v!) < 0
                            ? 'Mínimo inválido'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(p == null ? 'Crear producto' : 'Guardar cambios'),
                ),
                if (p != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final error = await widget.c.deactivateProduct(p.id);
                        if (!mounted) return;
                        if (error == null)
                          Navigator.pop(context);
                        else
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Desactivar producto'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MovementForm extends StatefulWidget {
  const MovementForm({super.key, required this.c, this.product});
  final InventoryController c;
  final Producto? product;
  @override
  State<MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends State<MovementForm> {
  final formKey = GlobalKey<FormState>();
  final quantity = TextEditingController();
  final reason = TextEditingController();
  String type = 'ENTRADA';
  String? productId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    productId = widget.product?.id;
  }

  @override
  void dispose() {
    quantity.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || productId == null) return;
    setState(() => saving = true);
    final error = await widget.c.movement(
      productoId: productId!,
      tipo: type,
      cantidad: int.parse(quantity.text),
      motivo: reason.text,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar movimiento',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: productId,
                  decoration: const InputDecoration(labelText: 'Producto'),
                  items: widget.c.listaProductos
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => productId = v),
                  validator: (v) => v == null ? 'Selecciona un producto' : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ENTRADA',
                      label: Text('Entrada'),
                      icon: Icon(Icons.add),
                    ),
                    ButtonSegment(
                      value: 'SALIDA',
                      label: Text('Salida'),
                      icon: Icon(Icons.remove),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setState(() => type = v.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n <= 0 ? 'Cantidad inválida' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reason,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrar movimiento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
