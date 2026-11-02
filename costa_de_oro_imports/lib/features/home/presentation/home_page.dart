import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = ApiClient();
  late final _auth = AuthRepository(_api);
  List<dynamic> _products = const [];
  String _name = 'Cliente';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.get('/api/productos'), _auth.profile()]);
      if (!mounted) return;
      _products = results[0] as List<dynamic>;
      final profile = results[1] as Map<String, dynamic>;
      _name = (profile['nombres'] ?? profile['correo'] ?? 'Cliente').toString();
    } on DioException catch (error) {
      if (!mounted) return;
      if (error.response?.statusCode == 401) {
        await _api.clearToken();
        context.go('/login');
        return;
      }
      _error = error.response?.data is Map
          ? error.response?.data['detail']?.toString()
          : 'No fue posible conectar con la API';
    } catch (_) {
      _error = 'No fue posible cargar el catálogo';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Costa de Oro Imports'),
          actions: [IconButton(onPressed: _logout, tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Hola, $_name', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 20),
                        Text('Productos', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (_products.isEmpty) const Text('No hay productos disponibles.'),
                        ..._products.map((item) {
                          final product = Map<String, dynamic>.from(item as Map);
                          return Card(
                            child: ListTile(
                              title: Text((product['nombre'] ?? 'Producto').toString()),
                              subtitle: Text((product['descripcion'] ?? '').toString()),
                              trailing: Text('\$${product['precio'] ?? ''}'),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      );
}
