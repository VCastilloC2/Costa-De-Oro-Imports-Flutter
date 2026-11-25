import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

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
  final _contactFormKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _requestType = 'PETICION';
  bool _isSending = false;

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

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitContact() async {
    if (!_contactFormKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final response = await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/perfil/contacto',
        data: {
          'asunto': _subjectController.text.trim(),
          'mensaje': _messageController.text.trim(),
          'tipo': _requestType,
        },
      );
      if (!mounted) return;
      final id = response.data?['id'];
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(id == null ? 'Solicitud enviada correctamente.' : 'Solicitud #$id enviada correctamente.'),
      ));
    } on DioException catch (error) {
      if (!mounted) return;
      final body = error.response?.data;
      final message = body is Map ? body['detail']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message ?? 'No se pudo enviar la solicitud. Revisa tu conexión e inténtalo de nuevo.'),
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
      return _notificationsContent();
    }
    if (widget.kind == 'contact') return _contactContent();
    if (widget.kind == 'privacy') return _privacyContent();
    return _helpContent();
  }

  Widget _pageBody({required IconData icon, required String eyebrow, required String title, required String description, required List<Widget> children}) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.brownDark, AppColors.brown]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.brownDark.withValues(alpha: .16), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.goldLight.withValues(alpha: .18), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppColors.goldLight, size: 25)),
            const SizedBox(height: 18),
            Text(eyebrow.toUpperCase(), style: AppFonts.style(size: 10, weight: FontWeight.w800, color: AppColors.goldLight, letterSpacing: 1.4)),
            const SizedBox(height: 7),
            Text(title, style: AppFonts.style(size: 24, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text(description, style: AppFonts.style(size: 14, weight: FontWeight.w400, color: Colors.white.withValues(alpha: .82), height: 1.45)),
          ]),
        ),
        const SizedBox(height: 18),
        ...children,
      ]);

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(18)}) => Container(
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border.withValues(alpha: .75)), boxShadow: [BoxShadow(color: AppColors.brownDark.withValues(alpha: .035), blurRadius: 14, offset: const Offset(0, 5))]),
        child: child,
      );

  Widget _contactContent() => _pageBody(
        icon: Icons.support_agent_rounded,
        eyebrow: 'Estamos para ayudarte',
        title: 'Hablemos',
        description: 'Cuéntanos qué necesitas. Tu solicitud quedará asociada a tu cuenta para que el equipo pueda darle seguimiento.',
        children: [
          _card(child: Form(
            key: _contactFormKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nueva solicitud', style: AppFonts.style(size: 17, weight: FontWeight.w800, color: AppColors.brownDark)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _requestType,
                decoration: _fieldDecoration('Tipo de solicitud', Icons.category_outlined),
                items: const [
                  DropdownMenuItem(value: 'PETICION', child: Text('Petición')),
                  DropdownMenuItem(value: 'QUEJA', child: Text('Queja')),
                  DropdownMenuItem(value: 'RECLAMO', child: Text('Reclamo')),
                  DropdownMenuItem(value: 'SUGERENCIA', child: Text('Sugerencia')),
                ],
                onChanged: (value) => setState(() => _requestType = value ?? 'PETICION'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subjectController,
                maxLength: 180,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration('Asunto', Icons.short_text_rounded),
                validator: (value) => (value?.trim().length ?? 0) < 4 ? 'Escribe un asunto de al menos 4 caracteres.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                minLines: 5,
                maxLines: 7,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration('Cuéntanos cómo podemos ayudarte', Icons.chat_bubble_outline_rounded),
                validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Agrega un poco más de detalle (mínimo 10 caracteres).' : null,
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: _isSending ? null : _submitContact,
                icon: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brownDark)) : const Icon(Icons.send_rounded),
                label: Text(_isSending ? 'Enviando…' : 'Enviar solicitud'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.goldLight, foregroundColor: AppColors.brownDark, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
            ]),
          )),
          const SizedBox(height: 12),
          _card(child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline_rounded, size: 19, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(child: Text('No incluyas contraseñas, códigos de verificación ni datos de tarjetas en tu mensaje.', style: TextStyle(color: AppColors.muted, height: 1.4))),
          ])),
        ],
      );

  InputDecoration _fieldDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
        filled: true,
        fillColor: AppColors.cream.withValues(alpha: .65),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border.withValues(alpha: .8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border.withValues(alpha: .8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
      );

  Widget _privacyContent() => _pageBody(
        icon: Icons.shield_outlined,
        eyebrow: 'Transparencia y confianza',
        title: 'Tu privacidad importa',
        description: 'Esta información resume cómo se usan los datos dentro de Costa de Oro Imports.',
        children: [
          _privacyCard(Icons.dataset_outlined, 'Datos que usamos', 'Nombre, correo, identificación y dirección, además de la información necesaria para administrar la cuenta y los pedidos.'),
          _privacyCard(Icons.local_shipping_outlined, 'Para qué los usamos', 'Procesar y entregar pedidos, gestionar tu cuenta y atender las solicitudes que envíes desde la aplicación.'),
          _privacyCard(Icons.manage_accounts_outlined, 'Tú tienes el control', 'Puedes revisar y actualizar tus datos personales desde Detalles de la cuenta.'),
          _privacyCard(Icons.verified_user_outlined, 'Protege tu cuenta', 'No compartas tu contraseña, códigos de verificación ni información de pago dentro de los mensajes de soporte.'),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () => context.push('/account-details'), icon: const Icon(Icons.open_in_new_rounded), label: const Text('Ir a Detalles de la cuenta'), style: TextButton.styleFrom(foregroundColor: AppColors.brown)),
        ],
      );

  Widget _privacyCard(IconData icon, String title, String description) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: _card(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.brown, size: 21)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppFonts.style(size: 15, weight: FontWeight.w700, color: AppColors.brownDark)),
            const SizedBox(height: 5),
            Text(description, style: AppFonts.style(size: 13, weight: FontWeight.w400, color: AppColors.muted, height: 1.45)),
          ])),
        ])),
      );

  Widget _helpContent() => _pageBody(
        icon: Icons.help_outline_rounded,
        eyebrow: 'Centro de ayuda',
        title: '¿En qué te ayudamos?',
        description: 'Respuestas rápidas para las tareas más comunes de tu cuenta.',
        children: [
          _card(padding: EdgeInsets.zero, child: Column(children: [
            _faq(Icons.person_outline_rounded, '¿Cómo actualizo mis datos?', 'Abre Perfil y entra en “Detalles de la cuenta”. Desde allí puedes revisar y editar tu información.', actionLabel: 'Abrir mi cuenta', onAction: () => context.push('/account-details')),
            _divider(),
            _faq(Icons.receipt_long_outlined, '¿Dónde veo mis pedidos y pagos?', 'En tu perfil encontrarás el historial con el estado, fecha, método de pago y total de cada pedido.', actionLabel: 'Ver historial', onAction: () => context.push('/payment-history')),
            _divider(),
            _faq(Icons.lock_reset_rounded, '¿Olvidé mi contraseña?', 'Cierra la sesión y usa “¿Olvidaste tu contraseña?” en la pantalla de inicio para recibir el código de recuperación.', actionLabel: 'Ir al acceso', onAction: () => context.go('/login')),
            _divider(),
            _faq(Icons.support_agent_rounded, '¿Necesito ayuda con otro tema?', 'Envía una petición, queja, reclamo o sugerencia. Quedará vinculada a tu cuenta.', actionLabel: 'Contactar', onAction: () => context.push('/contact')),
          ])),
          const SizedBox(height: 14),
          _card(child: const Row(children: [Icon(Icons.celebration_outlined, color: AppColors.goldDark), SizedBox(width: 10), Expanded(child: Text('Recuerda: la venta de bebidas alcohólicas es exclusiva para mayores de 18 años.', style: TextStyle(color: AppColors.brownDark, height: 1.4)))])),
        ],
      );

  Widget _faq(IconData icon, String title, String answer, {required String actionLabel, required VoidCallback onAction}) =>
      ExpansionTile(
        leading: Icon(icon, color: AppColors.brown),
        title: Text(title, style: AppFonts.style(size: 14, weight: FontWeight.w700, color: AppColors.brownDark)),
        collapsedIconColor: AppColors.muted,
        iconColor: AppColors.goldDark,
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(answer, style: AppFonts.style(size: 13, weight: FontWeight.w400, color: AppColors.muted, height: 1.45)), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: onAction, child: Text(actionLabel)))],
      );

  Widget _divider() => Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: AppColors.border.withValues(alpha: .65));

  Widget _notificationsContent() => _pageBody(
        icon: Icons.notifications_active_outlined,
        eyebrow: 'Preferencias',
        title: 'Tus notificaciones',
        description: 'Controla los avisos que quieres recibir en este dispositivo.',
        children: [
          _card(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _pushEnabled,
            activeThumbColor: AppColors.gold,
            secondary: const Icon(Icons.notifications_none_rounded, color: AppColors.brown),
            title: Text('Avisos de la aplicación', style: AppFonts.style(size: 15, weight: FontWeight.w700, color: AppColors.brownDark)),
            subtitle: Text('Preferencia guardada en este dispositivo.', style: AppFonts.style(size: 12, color: AppColors.muted)),
            onChanged: _saveNotificationPreference,
          )),
          const SizedBox(height: 12),
          _card(child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, color: AppColors.muted), SizedBox(width: 10), Expanded(child: Text('Los avisos de pedidos también están disponibles en tu historial. La recepción de notificaciones push requiere habilitar el servicio en el dispositivo.', style: TextStyle(color: AppColors.muted, height: 1.4)))])),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => context.push('/payment-history'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('Abrir historial de pedidos'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.brown, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 14))),
        ],
      );
}
