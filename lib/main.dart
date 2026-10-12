import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class Product {
  Product({required this.name, required this.stock, required this.color});

  final String name;
  int stock;
  final Color color;

  bool get isLowStock => stock <= 3;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final seed = Colors.green.shade700;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verde Stock',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xfff7faf7),
        ),
        scaffoldBackgroundColor: const Color(0xfff7faf7),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.green.shade50),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade400,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      home: InventoryShell(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: (enabled) {
          setState(() {
            _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
          });
        },
      ),
    );
  }
}

class InventoryShell extends StatefulWidget {
  const InventoryShell({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<InventoryShell> createState() => _InventoryShellState();
}

class _InventoryShellState extends State<InventoryShell> {
  int _selectedIndex = 0;
  String _search = '';
  bool _isSyncing = false;
  final _searchController = TextEditingController();
  final List<Product> _products = [
    Product(name: "Stevia D' Pais", stock: 3, color: Colors.green),
    Product(name: 'Vitamagne 200g', stock: 18, color: Colors.orange),
    Product(name: 'Bebida Dipluss', stock: 7, color: Colors.blue),
    Product(name: 'Concentrado De Alcachofa', stock: 2, color: Colors.teal),
    Product(name: 'Bolsa Compostable', stock: 32, color: Colors.brown),
    Product(name: 'R-Forte', stock: 11, color: Colors.indigo),
    Product(name: 'Aceite de Oregano', stock: 3, color: Colors.amber),
    Product(name: 'Cartimixx 100g', stock: 24, color: Colors.purple),
  ];

  List<Product> get _filteredProducts => _products
      .where(
        (product) =>
            product.name.toLowerCase().contains(_search.toLowerCase().trim()),
      )
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeStock(Product product, int amount) {
    setState(() {
      product.stock = (product.stock + amount).clamp(0, 999);
    });
  }

  void _addProduct() {
    final nameController = TextEditingController();
    final stockController = TextEditingController(text: '10');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock inicial',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final stock = int.tryParse(stockController.text) ?? 0;
              if (name.isEmpty) return;
              setState(() {
                _products.add(
                  Product(
                    name: name,
                    stock: stock.clamp(0, 999),
                    color: Colors.green,
                  ),
                );
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventario sincronizado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        products: _filteredProducts,
        searchController: _searchController,
        onSearchChanged: (value) => setState(() => _search = value),
      ),
      _ManagementPage(
        products: _filteredProducts,
        onIncrement: (product) => _changeStock(product, 1),
        onDecrement: (product) => _changeStock(product, -1),
        onAddProduct: _addProduct,
      ),
      _SettingsPage(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        isSyncing: _isSyncing,
        onSync: _syncNow,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Gestión',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.products,
    required this.searchController,
    required this.onSearchChanged,
  });

  final List<Product> products;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final lowStockCount = products
        .where((product) => product.isLowStock)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _PageHeader(
                  eyebrow: 'GESTIÓN INTELIGENTE',
                  title: 'Tu inventario',
                  subtitle: '$lowStockCount productos necesitan atención',
                  icon: Icons.eco,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.tune),
                  ),
                ),
              ),
            ),
            if (products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No encontramos ese producto')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCard(product: products[index]),
                    childCount: products.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: constraints.maxWidth > 600 ? 0.95 : 0.78,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ManagementPage extends StatelessWidget {
  const _ManagementPage({
    required this.products,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddProduct,
  });

  final List<Product> products;
  final ValueChanged<Product> onIncrement;
  final ValueChanged<Product> onDecrement;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: _PageHeader(
                    eyebrow: 'CONTROL DE STOCK',
                    title: 'Gestión',
                    subtitle: 'Actualiza tus productos al instante',
                    icon: Icons.inventory_2,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverList.builder(
            itemCount: products.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ManagementCard(
                product: products[index],
                onIncrement: () => onIncrement(products[index]),
                onDecrement: () => onDecrement(products[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.isSyncing,
    required this.onSync,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const _PageHeader(
          eyebrow: 'PREFERENCIAS',
          title: 'Ajustes',
          subtitle: 'Personaliza tu espacio de trabajo',
          icon: Icons.tune,
        ),
        const SizedBox(height: 24),
        Card(
          child: SwitchListTile(
            value: isDarkMode,
            onChanged: onThemeChanged,
            title: const Text(
              'Modo oscuro',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              isDarkMode ? 'Más cómodo para tus ojos' : 'Claro y luminoso',
            ),
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'CONEXIONES',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.green.withValues(alpha: .12),
                      child: Icon(Icons.table_chart, color: scheme.primary),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base de Datos',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text('Google Sheets conectado'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVO',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'inventario_verde_2024.xlsx',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 18, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isSyncing ? null : onSync,
                    icon: isSyncing
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      isSyncing ? 'Sincronizando...' : 'Sincronizar ahora',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Última sincronización'),
            subtitle: const Text('Hoy, 09:42 · Todos los cambios guardados'),
            trailing: Icon(Icons.check_circle, color: scheme.primary),
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: scheme.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLow = product.isLowStock;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 42,
                  color: product.color.withValues(alpha: .65),
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color: isLow ? Colors.orange : scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${product.stock} unidades',
                  style: TextStyle(
                    color: isLow
                        ? Colors.orange.shade800
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (isLow) ...[
              const SizedBox(height: 6),
              Text(
                'Stock crítico',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.product,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: product.color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.image_outlined, color: product.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.isLowStock ? 'Reponer pronto' : 'Stock disponible',
                    style: TextStyle(
                      color: product.isLowStock
                          ? Colors.orange
                          : scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: product.stock == 0 ? null : onDecrement,
              tooltip: 'Disminuir stock',
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${product.stock}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              tooltip: 'Aumentar stock',
              style: IconButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
              ),
              icon: Icon(Icons.add, color: scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
