// RAMA: feature/Products
// ============================================================================
// WIDGET: SalesMapCard
// ============================================================================
// Muestra un mapa vectorial interactivo de Colombia usando Syncfusion.
// Incluye controles de zoom personalizados y manejo de gestos.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../providers/map_sales_provider.dart';
import '../../../domain/map_sales_model.dart';

class SalesMapCard extends ConsumerStatefulWidget {
  const SalesMapCard({super.key});

  @override
  ConsumerState<SalesMapCard> createState() => _SalesMapCardState();
}

class _SalesMapCardState extends ConsumerState<SalesMapCard> {
  late final MapZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = MapZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      zoomLevel: 4.5, // Nivel inicial
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final mapAsync = ref.watch(mapSalesProvider);

    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa de Ventas',
            style: AppFonts.style(
              size: 18 * s,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            'Ventas acumuladas por ciudad principal',
            style: AppFonts.style(size: 12 * s, color: AppColors.muted),
          ),
          SizedBox(height: 16 * s),

          // AREA DEL MAPA
          ClipRRect(
            borderRadius: BorderRadius.circular(16 * s),
            child: SizedBox(
              height: 300 * s,
              width: double.infinity,
              child: mapAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.brownDark),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error al cargar los datos',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
                data: (cities) => _buildSyncfusionMap(cities, s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncfusionMap(List<CitySale> cities, double s) {
    return Stack(
      children: [
        // 1. EL MAPA
        SfMaps(
          layers: [
            MapShapeLayer(
              source: MapShapeSource.asset(
                'assets/maps/colombia.json',
                shapeDataField: 'NOMBRE_DPT',
              ),
              color: const Color(0xFFFDF4DE),
              strokeColor: const Color(0xFFD4AF37),
              strokeWidth: 0.8,
              zoomPanBehavior: _zoomPanBehavior,
              initialLatLngBounds: MapLatLngBounds(
                const MapLatLng(-4.0, -79.5),
                const MapLatLng(13.0, -66.0),
              ),
              initialMarkersCount: cities.length,
              markerBuilder: (BuildContext context, int index) {
                final city = cities[index];
                return MapMarker(
                  latitude: city.latitud,
                  longitude: city.longitud,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => _showCityDetails(context, city, s),
                    child: _buildMarker(city, s),
                  ),
                );
              },
            ),
          ],
        ),

        // 2. CONTROLES DE ZOOM Y CENTRADO
        Positioned(
          right: 12 * s,
          bottom: 12 * s,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlButton(
                icon: Icons.add,
                onTap: () {
                  if (_zoomPanBehavior.zoomLevel < 10) {
                    _zoomPanBehavior.zoomLevel =
                        _zoomPanBehavior.zoomLevel + 1;
                  }
                },
                s: s,
              ),
              SizedBox(height: 8 * s),
              _controlButton(
                icon: Icons.remove,
                onTap: () {
                  if (_zoomPanBehavior.zoomLevel > 1) {
                    _zoomPanBehavior.zoomLevel =
                        _zoomPanBehavior.zoomLevel - 1;
                  }
                },
                s: s,
              ),
              SizedBox(height: 8 * s),
              _controlButton(
                icon: Icons.center_focus_strong,
                onTap: () {
                  // Centrar de nuevo y volver al zoom inicial
                  setState(() {
                    _zoomPanBehavior.zoomLevel = 4.5;
                    // Puedes ajustar el centro si es necesario
                  });
                },
                s: s,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Botón personalizado para los controles del mapa
  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    required double s,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36 * s,
        height: 36 * s,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          icon,
          size: 20 * s,
          color: AppColors.brownDark,
        ),
      ),
    );
  }

  Widget _buildMarker(CitySale city, double s) {
    return Container(
      width: 36 * s,
      height: 36 * s,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
            blurRadius: 8 * s,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${city.ventas}',
        style: AppFonts.style(
          size: 11 * s,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showCityDetails(BuildContext context, CitySale city, double s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20 * s),
        ),
        title: Text(
          city.ciudad,
          style: AppFonts.style(
            size: 18 * s,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: AppColors.brown,
                ),
                SizedBox(width: 8 * s),
                Text(
                  'Ventas: ${city.ventas}',
                  style: AppFonts.style(
                    size: 14 * s,
                    color: AppColors.brownDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * s),
            Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 20,
                  color: AppColors.brown,
                ),
                SizedBox(width: 8 * s),
                Text(
                  'Empresas: ${city.empresasCompradoras}',
                  style: AppFonts.style(
                    size: 14 * s,
                    color: AppColors.brownDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar',
              style: AppFonts.style(
                size: 14 * s,
                weight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}