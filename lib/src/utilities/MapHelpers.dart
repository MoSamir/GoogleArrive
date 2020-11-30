import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as Math;

class MapHelpers {

  static  double getDistanceBetweenPoints({LatLng pointA , LatLng pointB}) {
    var p = Math.pi;
    var c = Math.cos;
    var a = 0.5 -
        c((pointB.latitude - pointA.latitude) * p) / 2 +
        c(pointA.latitude * p) * c(pointB.latitude * p) * (1 - c((pointB.longitude - pointA.longitude) * p)) / 2;
    return 12742 * Math.asin(Math.sqrt(a));
  }



}