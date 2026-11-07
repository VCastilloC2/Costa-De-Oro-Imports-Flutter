import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.creamDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER PERSONALIZADO ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.brown,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Términos y Condiciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ],
                ),
              ),

              // --- CONTENIDO ---
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner de bienvenida
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.gavel_rounded,
                              color: AppColors.goldDark,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Reglas de la casa',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brownDark,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Para que todos disfruten de la mejor experiencia (y de los mejores licores), aquí te contamos cómo funciona Costa de Oro.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Última actualización: 24 de Octubre de 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Tarjetas de los Términos
                      _buildTermCard(
                        icon: Icons.sports_bar_rounded,
                        title: '1. Mayoría de Edad (18+)',
                        description: 'Al usar esta app, confirmas que tienes más de 18 años. En Costa de Oro nos tomamos esto muy en serio; si al entregar el pedido no puedes comprobar tu edad, no podremos dejarte el licor.',
                      ),
                      _buildTermCard(
                        icon: Icons.favorite_rounded,
                        title: '2. Consumo Responsable',
                        description: 'Queremos que disfrutes, pero siempre con medida. La app no se hace responsable por el uso indebido de los productos. Si vas a beber, no manejes.',
                      ),
                      _buildTermCard(
                        icon: Icons.security_rounded,
                        title: '3. Privacidad de Datos',
                        description: 'Tus datos (nombre, correo, cédula y dirección) son solo para procesar y entregar tus pedidos. Jamás venderemos tu información a terceros. Tu privacidad es nuestra prioridad.',
                      ),
                      _buildTermCard(
                        icon: Icons.local_shipping_rounded,
                        title: '4. Envíos y Entregas',
                        description: 'Hacemos envíos a las zonas autorizadas. Recuerda tener tu documento de identidad a la mano, el repartidor está obligado a pedírtelo antes de entregar.',
                      ),
                      _buildTermCard(
                        icon: Icons.copyright_rounded,
                        title: '5. Propiedad Intelectual',
                        description: 'Todo el diseño, los logos y la información de esta app son propiedad exclusiva de Costa de Oro Imports. No está permitido copiar o usar nuestro contenido sin permiso.',
                      ),

                      SizedBox(height: 32),

                      // Botón inferior
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brown,
                            foregroundColor: AppColors.creamText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'Entendido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para construir cada tarjeta de término de forma limpia
  Widget _buildTermCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono en un círculo
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.goldDark, size: 24),
          ),
          SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brownDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.brown.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
