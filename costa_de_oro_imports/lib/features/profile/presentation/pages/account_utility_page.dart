import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_client.dart';

class AccountUtilityPage extends ConsumerStatefulWidget {
  const AccountUtilityPage({super.key, required this.kind});
  final String kind;

  @override
  ConsumerState<AccountUtilityPage> createState() => _AccountUtilityPageState();
}

class _AccountUtilityPageState extends ConsumerState<AccountUtilityPage> {
  late Future<List<dynamic>> _orders;
  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    _orders = _loadOrders();
    if (widget.kind == 'notifications') _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _pushEnabled = prefs.getBool('app_notifications_enabled') ?? true);
  }

  Future<void> _saveNotificationPreference(bool value) async {
    setState(() => _pushEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notifications_enabled', value);
  }

  Future<List<dynamic>> _loadOrders() async {
    if (widget.kind != 'orders' && widget.kind != 'payment-history') return const [];
    final path = widget.kind == 'orders' ? '/admin/compra' : '/perfil/pedidos';
    final response = await ref.read(dioProvider).get<List<dynamic>>(path);
    return response.data ?? const [];
  }

  String get _title => switch (widget.kind) {
        'orders' => 'Pedidos',
        'payment-history' => 'Historial de pagos',
        'notifications' => 'Notificaciones',
        'contact' => 'Contactanos',
        'privacy' => 'Politica de privacidad',
        _ => 'Obtener ayuda',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.brownDark,
        elevation: 0,
        title: Text(_title, style: AppFonts.style(size: 19, weight: FontWeight.w700, color: AppColors.brownDark)),
      ),
      body: SafeArea(child: _content()),
    );
  }

  Widget _content() {
    if (widget.kind == 'orders' || widget.kind == 'payment-history') {
      return FutureBuilder<List<dynamic>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('No se pudieron cargar los pedidos. Revisa tu conexión e inténtalo de nuevo.'),
              TextButton(onPressed: () => setState(() => _orders = _loadOrders()), child: const Text('Reintentar')),
            ])));
          }
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) return const Center(child: Text('Aún no tienes pedidos registrados.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = Map<String, dynamic>.from(rows[index] as Map);
              final total = row['total'] ?? 0;
              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text('${row['numero_orden'] ?? row['numeroOrden'] ?? 'Pedido'} · ${row['estado'] ?? 'En proceso'}'),
                  subtitle: Text('${row['fecha'] ?? ''}${(row['metodoPago'] ?? row['metodo_pago']) != null ? ' · ${row['metodoPago'] ?? row['metodo_pago']}' : ''}'),
                  trailing: Text('\$${total is num ? total.toStringAsFixed(0) : total}'),
                ),
              );
            },
          );
        },
      );
    }
    if (widget.kind == 'notifications') {
      return ListView(children: [
        SwitchListTile(
          value: _pushEnabled,
          activeThumbColor: AppColors.gold,
          title: const Text('Notificaciones de la app'),
          subtitle: const Text('Recibe novedades y avisos de tu cuenta en este dispositivo.'),
          onChanged: _saveNotificationPreference,
        ),
        const ListTile(title: Text('Avisos de pedidos'), subtitle: Text('Consulta el estado de tus pedidos desde Historial de pagos.')),
      ]);
    }
    final text = switch (widget.kind) {
      'contact' => 'Para recibir ayuda, indícanos el correo de tu cuenta y describe el inconveniente. Puedes consultar las preguntas frecuentes desde “Obtener ayuda”.',
      'privacy' => 'Los datos de nombre, correo, identificación y dirección se utilizan para procesar y entregar pedidos, de acuerdo con los términos de Costa de Oro Imports. Puedes revisar y corregir tus datos desde Perfil > Detalles de la cuenta.',
      _ => 'Puedes revisar tus pedidos y pagos en el historial, editar tus datos desde Detalles de la cuenta o consultar las preguntas frecuentes de esta sección.',
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: AppFonts.style(size: 16, weight: FontWeight.w400, color: AppColors.brownDark)),
        if (widget.kind == 'help') ...[
          const SizedBox(height: 24),
          const Text('¿Cómo cambio mis datos? Abre Perfil > Detalles de la cuenta.'),
          const SizedBox(height: 12),
          const Text('¿Olvidaste tu contraseña? Usa “¿Olvidaste tu contraseña?” en la pantalla de inicio de sesión.'),
          const SizedBox(height: 12),
          const Text('¿Necesitas revisar un pedido? Abre Perfil > Historial de pagos.'),
          TextButton(onPressed: () => context.push('/contact'), child: const Text('Contactar soporte')),
        ],
      ]),
    );
  }
}
