import 'package:flutter/material.dart';

/// Defines a selectable zone on the court
class CourtZone {
  final String id;
  final String name;
  final Rect rect; // For simplicity, using rectangular zones
  final Color baseColor;

  CourtZone({
    required this.id,
    required this.name,
    required this.rect,
    required this.baseColor,
  });
}

/// Court layout configuration for different sports
class CourtLayout {
  final Color backgroundColor;
  final List<CourtZone> zones;

  CourtLayout({required this.backgroundColor, required this.zones});
}

/// Factory to get layouts for different sports
Map<String, CourtLayout> getCourtLayouts() {
  return {
    'badminton': CourtLayout(
      backgroundColor: const Color(0xFF1B5E20), // Dark Green
      zones: [
        CourtZone(
          id: 'front-left',
          name: 'Front Left',
          rect: const Rect.fromLTWH(20, 150, 130, 100),
          baseColor: const Color(0xFF4CAF50),
        ),
        CourtZone(
          id: 'front-right',
          name: 'Front Right',
          rect: const Rect.fromLTWH(150, 150, 130, 100),
          baseColor: const Color(0xFF4CAF50),
        ),
        CourtZone(
          id: 'back-left',
          name: 'Back Left',
          rect: const Rect.fromLTWH(20, 250, 130, 130),
          baseColor: const Color(0xFF388E3C),
        ),
        CourtZone(
          id: 'back-right',
          name: 'Back Right',
          rect: const Rect.fromLTWH(150, 250, 130, 130),
          baseColor: const Color(0xFF388E3C),
        ),
      ],
    ),
    'cricket': CourtLayout(
      backgroundColor: const Color(0xFF795548), // Brown/Pitch
      zones: [
        CourtZone(
          id: 'striker',
          name: 'Striker End',
          rect: const Rect.fromLTWH(100, 300, 100, 80),
          baseColor: const Color(0xFFD7CCC8),
        ),
        CourtZone(
          id: 'non-striker',
          name: 'Non-Striker',
          rect: const Rect.fromLTWH(100, 20, 100, 80),
          baseColor: const Color(0xFFD7CCC8),
        ),
        CourtZone(
          id: 'mid-wicket',
          name: 'Mid Wicket',
          rect: const Rect.fromLTWH(20, 120, 80, 160),
          baseColor: const Color(0xFFA1887F),
        ),
        CourtZone(
          id: 'off-side',
          name: 'Off Side',
          rect: const Rect.fromLTWH(200, 120, 80, 160),
          baseColor: const Color(0xFFA1887F),
        ),
      ],
    ),
    'football': CourtLayout(
      backgroundColor: const Color(0xFF2E7D32), // Green
      zones: [
        CourtZone(
          id: 'goalkeeper',
          name: 'Goal Keeper',
          rect: const Rect.fromLTWH(100, 320, 100, 60),
          baseColor: const Color(0xFF66BB6A),
        ),
        CourtZone(
          id: 'defense',
          name: 'Defense',
          rect: const Rect.fromLTWH(20, 220, 260, 100),
          baseColor: const Color(0xFF81C784),
        ),
        CourtZone(
          id: 'midfield',
          name: 'Midfield',
          rect: const Rect.fromLTWH(20, 120, 260, 100),
          baseColor: const Color(0xFF66BB6A),
        ),
        CourtZone(
          id: 'attack',
          name: 'Attack',
          rect: const Rect.fromLTWH(20, 20, 260, 100),
          baseColor: const Color(0xFF81C784),
        ),
      ],
    ),
    'tennis': CourtLayout(
      backgroundColor: const Color(0xFF1565C0), // Blue
      zones: [
        CourtZone(
          id: 'baseline',
          name: 'Baseline',
          rect: const Rect.fromLTWH(20, 300, 260, 80),
          baseColor: const Color(0xFF42A5F5),
        ),
        CourtZone(
          id: 'service-left',
          name: 'Service Left',
          rect: const Rect.fromLTWH(20, 160, 130, 140),
          baseColor: const Color(0xFF64B5F6),
        ),
        CourtZone(
          id: 'service-right',
          name: 'Service Right',
          rect: const Rect.fromLTWH(150, 160, 130, 140),
          baseColor: const Color(0xFF64B5F6),
        ),
        CourtZone(
          id: 'net',
          name: 'Net Area',
          rect: const Rect.fromLTWH(20, 80, 260, 80),
          baseColor: const Color(0xFF90CAF9),
        ),
      ],
    ),
  };
}

/// Custom Painter for the court
class _CourtPainter extends CustomPainter {
  final CourtLayout layout;
  final String? selectedZoneId;

  _CourtPainter({required this.layout, this.selectedZoneId});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = layout.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw each zone
    for (final zone in layout.zones) {
      final isSelected = zone.id == selectedZoneId;
      final paint = Paint()
        ..color = isSelected ? Colors.amber : zone.baseColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(zone.rect, const Radius.circular(8)),
        paint,
      );

      // Border
      final borderPaint = Paint()
        ..color = isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(zone.rect, const Radius.circular(8)),
        borderPaint,
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: zone.name,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: zone.rect.width);
      textPainter.paint(
        canvas,
        Offset(
          zone.rect.left + (zone.rect.width - textPainter.width) / 2,
          zone.rect.top + (zone.rect.height - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CourtPainter oldDelegate) {
    return oldDelegate.selectedZoneId != selectedZoneId;
  }
}

/// Interactive Court Map Widget
class CourtMapWidget extends StatefulWidget {
  final String sportType;
  final ValueChanged<CourtZone?> onZoneSelected;

  const CourtMapWidget({
    super.key,
    required this.sportType,
    required this.onZoneSelected,
  });

  @override
  State<CourtMapWidget> createState() => _CourtMapWidgetState();
}

class _CourtMapWidgetState extends State<CourtMapWidget> {
  String? _selectedZoneId;
  late CourtLayout _layout;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  @override
  void didUpdateWidget(covariant CourtMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sportType != widget.sportType) {
      _loadLayout();
    }
  }

  void _loadLayout() {
    final layouts = getCourtLayouts();
    final key = widget.sportType.toLowerCase();
    _layout = layouts[key] ?? layouts['badminton']!;
    _selectedZoneId = null;
  }

  void _handleTap(TapDownDetails details) {
    final localPos = details.localPosition;
    for (final zone in _layout.zones) {
      if (zone.rect.contains(localPos)) {
        setState(() {
          _selectedZoneId = _selectedZoneId == zone.id ? null : zone.id;
        });
        widget.onZoneSelected(_selectedZoneId != null ? zone : null);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Position',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap on a zone to choose your playing position',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTapDown: _handleTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 0.75, // Width / Height
                child: CustomPaint(
                  painter: _CourtPainter(
                    layout: _layout,
                    selectedZoneId: _selectedZoneId,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_selectedZoneId != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Position: ${_layout.zones.firstWhere((z) => z.id == _selectedZoneId).name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
