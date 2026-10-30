// lib/utils/geo_utils.dart
//
// Todas as operações geoespaciais necessárias, sem dependências externas.
// Baseado em algoritmos padrão de geometria computacional.

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoUtils {
  // Raio médio da Terra em metros
  static const double _earthRadiusMeters = 6371000.0;

  // ─────────────────────────────────────────────────────────────────────────
  // DISTÂNCIA entre dois pontos (Haversine Formula)
  // Retorna a distância em METROS.
  // ─────────────────────────────────────────────────────────────────────────
  static double distanceMeters(LatLng a, LatLng b) {
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);

    final h = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return _earthRadiusMeters * c;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPRIMENTO TOTAL de um caminho (polyline) em metros
  // ─────────────────────────────────────────────────────────────────────────
  static double pathLengthMeters(List<LatLng> path) {
    if (path.length < 2) return 0.0;
    double total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      total += distanceMeters(path[i], path[i + 1]);
    }
    return total;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PONTO DENTRO DO POLÍGONO — Ray Casting Algorithm
  //
  // Retorna true se o ponto [p] estiver dentro do polígono [polygon].
  // O polígono deve ser uma lista fechada ou não (o algoritmo funciona nos
  // dois casos).
  // ─────────────────────────────────────────────────────────────────────────
  static bool isPointInPolygon(LatLng p, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    final int n = polygon.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final LatLng pi = polygon[i];
      final LatLng pj = polygon[j];

      // Verifica se o raio horizontal a partir de [p] cruza o segmento [pj-pi]
      final bool intersects =
          ((pi.latitude > p.latitude) != (pj.latitude > p.latitude)) &&
              (p.longitude <
                  (pj.longitude - pi.longitude) *
                          (p.latitude - pi.latitude) /
                          (pj.latitude - pi.latitude) +
                      pi.longitude);

      if (intersects) inside = !inside;
    }
    return inside;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // O CAMINHO CRUZA O POLÍGONO?
  //
  // Retorna true se QUALQUER ponto do caminho estiver dentro do polígono,
  // OU se o caminho INTERSECTA algum segmento do polígono.
  // Isso cobre dois casos:
  //   1. O runner passou por dentro do território alheio.
  //   2. O runner contorna o território (linha cruza a borda).
  // ─────────────────────────────────────────────────────────────────────────
  static bool doesPathCrossPolygon(
      List<LatLng> path, List<LatLng> polygon) {
    if (path.isEmpty || polygon.length < 3) return false;

    // Caso 1: algum ponto da rota está dentro do polígono
    for (final point in path) {
      if (isPointInPolygon(point, polygon)) return true;
    }

    // Caso 2: algum segmento da rota cruza um segmento do polígono
    for (int i = 0; i < path.length - 1; i++) {
      for (int j = 0; j < polygon.length; j++) {
        final LatLng pa = path[i];
        final LatLng pb = path[i + 1];
        final LatLng pc = polygon[j];
        final LatLng pd = polygon[(j + 1) % polygon.length];
        if (_segmentsIntersect(pa, pb, pc, pd)) return true;
      }
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // O CAMINHO FECHA UM POLÍGONO?
  //
  // Verifica se o último ponto do caminho está suficientemente próximo do
  // primeiro ponto (dentro de [closingThresholdMeters]).
  // Usa isso para detectar que o runner completou um circuito fechado.
  // ─────────────────────────────────────────────────────────────────────────
  static bool isPathClosed(
    List<LatLng> path, {
    double closingThresholdMeters = 30.0,
    int minPoints = 10,
  }) {
    if (path.length < minPoints) return false;
    final dist = distanceMeters(path.first, path.last);
    return dist <= closingThresholdMeters;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ÁREA DO POLÍGONO em metros quadrados (Shoelace / Gauss's area formula
  // adaptada para coordenadas geográficas)
  // ─────────────────────────────────────────────────────────────────────────
  static double polygonAreaSqMeters(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;

    // Projeta para coordenadas cartesianas aproximadas centradas no centróide
    final center = _centroid(polygon);
    final cosLat = math.cos(_toRad(center.latitude));

    double area = 0;
    final int n = polygon.length;
    for (int i = 0; i < n; i++) {
      final LatLng a = polygon[i];
      final LatLng b = polygon[(i + 1) % n];

      // Converte diferença de graus para metros
      final double x1 = _toRad(a.longitude - center.longitude) *
          _earthRadiusMeters *
          cosLat;
      final double y1 =
          _toRad(a.latitude - center.latitude) * _earthRadiusMeters;
      final double x2 = _toRad(b.longitude - center.longitude) *
          _earthRadiusMeters *
          cosLat;
      final double y2 =
          _toRad(b.latitude - center.latitude) * _earthRadiusMeters;

      area += (x1 * y2) - (x2 * y1);
    }

    return (area / 2).abs();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VELOCIDADE MÁXIMA ao longo do caminho
  //
  // Retorna a velocidade máxima em km/h entre segmentos consecutivos.
  // ─────────────────────────────────────────────────────────────────────────
  static double maxSpeedKmh(List<LatLng> path, List<DateTime> timestamps) {
    if (path.length < 2 || timestamps.length != path.length) return 0.0;

    double maxSpeed = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final distM = distanceMeters(path[i], path[i + 1]);
      final timeSec =
          timestamps[i + 1].difference(timestamps[i]).inMilliseconds / 1000.0;

      if (timeSec <= 0) continue;

      final speedMs = distM / timeSec; // metros por segundo
      final speedKmh = speedMs * 3.6;
      if (speedKmh > maxSpeed) maxSpeed = speedKmh;
    }
    return maxSpeed;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VELOCIDADE MÉDIA ao longo do caminho total
  // ─────────────────────────────────────────────────────────────────────────
  static double avgSpeedKmh(List<LatLng> path, List<DateTime> timestamps) {
    if (path.length < 2 || timestamps.isEmpty) return 0.0;

    final totalDistM = pathLengthMeters(path);
    final totalTimeSec =
        timestamps.last.difference(timestamps.first).inSeconds.toDouble();

    if (totalTimeSec <= 0) return 0.0;

    return (totalDistM / totalTimeSec) * 3.6;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONVEX HULL — converte uma lista de pontos no menor polígono convexo
  // (útil para gerar território a partir de um trajeto fechado)
  // Algoritmo de Graham Scan
  // ─────────────────────────────────────────────────────────────────────────
  static List<LatLng> convexHull(List<LatLng> points) {
    if (points.length < 3) return points;

    // Ordena por latitude depois longitude
    final sorted = List<LatLng>.from(points)
      ..sort((a, b) {
        final cmp = a.latitude.compareTo(b.latitude);
        return cmp != 0 ? cmp : a.longitude.compareTo(b.longitude);
      });

    List<LatLng> lower = [];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          _cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    List<LatLng> upper = [];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          _cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return lower + upper;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVADOS
  // ─────────────────────────────────────────────────────────────────────────

  static double _toRad(double deg) => deg * math.pi / 180.0;

  static LatLng _centroid(List<LatLng> polygon) {
    double lat = 0, lng = 0;
    for (final p in polygon) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / polygon.length, lng / polygon.length);
  }

  // Produto vetorial 2D — positivo = sentido anti-horário
  static double _cross(LatLng o, LatLng a, LatLng b) {
    return (a.latitude - o.latitude) * (b.longitude - o.longitude) -
        (a.longitude - o.longitude) * (b.latitude - o.latitude);
  }

  // Verifica se os segmentos AB e CD se intersectam
  static bool _segmentsIntersect(
      LatLng a, LatLng b, LatLng c, LatLng d) {
    final d1 = _direction(c, d, a);
    final d2 = _direction(c, d, b);
    final d3 = _direction(a, b, c);
    final d4 = _direction(a, b, d);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    if (d1 == 0 && _onSegment(c, d, a)) return true;
    if (d2 == 0 && _onSegment(c, d, b)) return true;
    if (d3 == 0 && _onSegment(a, b, c)) return true;
    if (d4 == 0 && _onSegment(a, b, d)) return true;

    return false;
  }

  static double _direction(LatLng pi, LatLng pj, LatLng pk) {
    return (pk.latitude - pi.latitude) * (pj.longitude - pi.longitude) -
        (pj.latitude - pi.latitude) * (pk.longitude - pi.longitude);
  }

  static bool _onSegment(LatLng pi, LatLng pj, LatLng pk) {
    return math.min(pi.latitude, pj.latitude) <= pk.latitude &&
        pk.latitude <= math.max(pi.latitude, pj.latitude) &&
        math.min(pi.longitude, pj.longitude) <= pk.longitude &&
        pk.longitude <= math.max(pi.longitude, pj.longitude);
  }
}
