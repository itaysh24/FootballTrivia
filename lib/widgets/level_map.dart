// level_map.dart
// A scrollable level map widget with SVG parsing that supports xml ^6.5.0.
// Inline notes are included to explain each part.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' as xml;

/// Model representing one level point on the map
class LevelPoint {
  final double x;
  final double y;
  final int id;
  final bool locked;
  LevelPoint({
    required this.x,
    required this.y,
    required this.id,
    this.locked = false,
  });
}

/// Color configuration for different leagues
class LeagueColors {
  final Color unlockedColor;
  final Color lockedColor;
  final Color borderColor;
  final Color textColor;

  const LeagueColors({
    required this.unlockedColor,
    required this.lockedColor,
    required this.borderColor,
    required this.textColor,
  });

  // Predefined color schemes for different leagues
  static const LeagueColors english = LeagueColors(
    unlockedColor: Color.fromARGB(255, 255, 255, 255), // White
    lockedColor: Colors.grey,
    borderColor: Color.fromARGB(255, 68, 0, 255), // Purple
    textColor: Color.fromARGB(255, 0, 0, 255), // Blue
  );

  static const LeagueColors spanish = LeagueColors(
    unlockedColor: Color.fromARGB(255, 255, 215, 0), // Gold
    lockedColor: Colors.grey,
    borderColor: Color.fromARGB(255, 255, 0, 0), // Red
    textColor: Color.fromARGB(255, 255, 255, 255), // White
  );

  static const LeagueColors german = LeagueColors(
    unlockedColor: Color.fromARGB(255, 255, 255, 0), // Yellow
    lockedColor: Colors.grey,
    borderColor: Color.fromARGB(255, 0, 0, 0), // Black
    textColor: Color.fromARGB(255, 0, 0, 0), // Black
  );

  static const LeagueColors italian = LeagueColors(
    unlockedColor: Color.fromARGB(255, 0, 255, 0), // Green
    lockedColor: Colors.grey,
    borderColor: Color.fromARGB(255, 255, 255, 255), // White
    textColor: Color.fromARGB(255, 0, 0, 0), // Black
  );

  static const LeagueColors french = LeagueColors(
    unlockedColor: Color.fromARGB(255, 0, 0, 255), // Blue
    lockedColor: Colors.grey,
    borderColor: Color.fromARGB(255, 255, 255, 255), // White
    textColor: Color.fromARGB(255, 255, 255, 255), // White
  );
}

/// Holds parsed SVG data (points + viewBox info)
class SvgMapData {
  final List<LevelPoint> points;
  final double viewMinX;
  final double viewMinY;
  final double viewWidth;
  final double viewHeight;

  SvgMapData({
    required this.points,
    required this.viewMinX,
    required this.viewMinY,
    required this.viewWidth,
    required this.viewHeight,
  });

  /// Parse SVG from raw string
  static SvgMapData parseFromString(String svgString) {
    final doc = xml.XmlDocument.parse(svgString);
    final svgElem = doc.findAllElements('svg').isNotEmpty
        ? doc.findAllElements('svg').first
        : doc.rootElement;

    // Extract viewBox or width/height info
    double minX = 0, minY = 0, vbW = 0, vbH = 0;
    final viewBox = svgElem.getAttribute('viewBox');
    if (viewBox != null) {
      final parts = viewBox
          .split(RegExp(r'[\s,]+'))
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();
      if (parts.length == 4) {
        minX = parts[0];
        minY = parts[1];
        vbW = parts[2];
        vbH = parts[3];
      }
    }

    // fallback to width/height if viewBox not provided
    double parseDim(String? val) {
      if (val == null) return 0.0;
      final m = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(val.trim());
      if (m == null) return 0.0;
      return double.parse(m.group(1)!);
    }

    if (vbW == 0 || vbH == 0) {
      vbW = parseDim(svgElem.getAttribute('width'));
      vbH = parseDim(svgElem.getAttribute('height'));
    }

    final points = <LevelPoint>[];

    // --- Parse circle nodes into LevelPoints ---
    for (final circle in svgElem.findAllElements('circle')) {
      final cx = double.tryParse(circle.getAttribute('cx') ?? '0') ?? 0.0;
      final cy = double.tryParse(circle.getAttribute('cy') ?? '0') ?? 0.0;
      points.add(LevelPoint(x: cx - minX, y: cy - minY, id: points.length));
    }

    return SvgMapData(
      points: points,
      viewMinX: minX,
      viewMinY: minY,
      viewWidth: vbW,
      viewHeight: vbH,
    );
  }

  /// Load from asset path
  static Future<SvgMapData> fromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return parseFromString(raw);
  }
}

/// Widget that displays the level map as a scrollable canvas
class LevelMap extends StatelessWidget {
  final SvgMapData mapData;
  final Widget Function(BuildContext, LevelPoint) markerBuilder;
  final String? backgroundImage;

  const LevelMap({
    super.key,
    required this.mapData,
    required this.markerBuilder,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mapData.viewWidth,
      height: mapData.viewHeight,
      child: Stack(
        children: [
          // Background map image if provided
          if (backgroundImage != null)
            Positioned.fill(
              child: Image.asset(backgroundImage!, fit: BoxFit.cover),
            ),
          // Level points
          for (final point in mapData.points)
            Positioned(
              left: point.x,
              top: point.y,
              child: markerBuilder(context, point),
            ),
        ],
      ),
    );
  }
}

// Customizable marker widget with league-specific colors
class DefaultMarker extends StatelessWidget {
  final int id;
  final bool locked;
  final Color? unlockedColor;
  final Color? lockedColor;
  final Color? borderColor;
  final Color? textColor;

  const DefaultMarker({
    super.key,
    required this.id,
    this.locked = false,
    this.unlockedColor,
    this.lockedColor,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Default colors if none provided
    final defaultUnlockedColor = const Color.fromARGB(255, 255, 255, 255);
    final defaultLockedColor = Colors.grey.shade600;
    final defaultBorderColor = const Color.fromARGB(255, 68, 0, 255);
    final defaultTextColor = const Color.fromARGB(255, 0, 0, 255);

    return Container(
      width: 35,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: locked
            ? (lockedColor ?? defaultLockedColor)
            : (unlockedColor ?? defaultUnlockedColor),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? defaultBorderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$id',
        style: TextStyle(
          color: textColor ?? defaultTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

/*
Notes:
- LevelPoint: represents a single point (level) parsed from SVG.
- SvgMapData: parses SVG <circle> elements into LevelPoints. Handles viewBox.
- LevelMap widget: renders points on a fixed canvas with no zoom/scroll functionality.
- markerBuilder: lets you provide custom UI for each level (e.g., locked/unlocked state).
- DefaultMarker: example circle marker widget with enhanced visibility.
*/
