import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as Math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_drive/src/blocs/MapViewBloc.dart';
import 'package:google_drive/src/utilities/MapHelpers.dart';

import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';



class GoogleViewScreen extends StatefulWidget {
  @override
  _GoogleViewScreenState createState() => _GoogleViewScreenState();
}

class _GoogleViewScreenState extends State<GoogleViewScreen> {


  static  CameraPosition cameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 10.4746,
  );
  Set<Marker> markers = HashSet<Marker>();
  Set<Polyline> roadPolygon = HashSet<Polyline>();
  GoogleMapController googleMapController ;
  GoogleMapPolyline googleMapPolyline = new GoogleMapPolyline(apiKey: "API-Key");
  List<LatLng> polylineCoordinates = List<LatLng>();
  MapViewBloc _mapBloc = MapViewBloc(MapViewLoadingState());



  @override
  void initState() {
    super.initState();
    _mapBloc.add(GetUserLocation());
  }

  @override
  void dispose() {
    _mapBloc.close();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
        cubit: _mapBloc,
        builder: (context , state){
          if(state is MapViewLoadedState){

            if(markers.length == 0){
              if(googleMapController != null){

                googleMapController.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                    bearing: 0,
                    target: LatLng(state.userLocation.latitude, state.userLocation.longitude),
                    zoom: 17.0,
                  ),
                ));
              }
              else {
                cameraPosition = CameraPosition(
                  target: LatLng(state.userLocation.latitude, state.userLocation.longitude),
                  zoom: 10.4746,
                );
              }
            }

            return ModalProgressHUD(
              inAsyncCall: state is MapViewLoadingState,
              child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: ()=> _mapBloc.add(GetUserLocation()),
                  backgroundColor: Colors.yellow,
                  child: Icon(Icons.location_history),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child:  GoogleMap(
                        markers: markers,
                        polylines: roadPolygon,
                        mapType: MapType.normal,
                        onTap: (LatLng tappedPosition) async {
                          if(markers.length == 2){
                            return;
                          }
                          markers.add(Marker(
                            markerId: MarkerId('L${markers.length}'),
                            position: tappedPosition,
                          ),);
                          setState(() {});
                          await refreshPath();
                        },
                        initialCameraPosition: cameraPosition,
                        onMapCreated: (GoogleMapController controller) {
                          googleMapController = controller;
                        },
                      ),
                    ),
                    FlatButton(
                      onPressed: (){
                        setState(() {
                          markers.clear();
                          roadPolygon.clear();
                        });
                      },
                      child: Text('Reset'),
                    ),
                  ],
                ),
              ),
            );
          }
          else if(state is MapViewErrorState){
            return Scaffold(
              body: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Please Check your connectivity and try again'),
                    FlatButton(
                      child: Text('Retry'),
                      onPressed: ()=> _mapBloc.add(GetUserLocation()),
                    ),
                  ],
                ),
              ),
            );
          }
          else {
            return Scaffold(
              body: ModalProgressHUD(
                  inAsyncCall: state is MapViewLoadingState,
                  child: Container()),
            );
          }
    }, listener: (context, state){

    });
  }

  Future<void> refreshPath() async {
    if(markers.length == 2){
      Marker source = markers.elementAt(0), distention  = markers.elementAt(1);

      polylineCoordinates = await googleMapPolyline.getCoordinatesWithLocation(
          origin: LatLng(source.position.latitude , source.position.longitude),
          destination: LatLng(distention.position.latitude , distention.position.longitude),
          mode: RouteMode.driving);

      if(polylineCoordinates != null ){
        Polyline polyline = Polyline(
            visible: true,
            width: 5,
            zIndex: 0,
            polylineId: PolylineId('Pol#1'),
            color: Colors.red,
            points: polylineCoordinates
        );
        roadPolygon.add(polyline);
        writeToFirebase(source,distention ,calculateDistance());
      }
    }
    setState(() {});
  }


  double calculateDistance() {
    double totalDistance = 0.0;
    if (polylineCoordinates != null && polylineCoordinates.isNotEmpty) {
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += MapHelpers.getDistanceBetweenPoints(
          pointA : LatLng(polylineCoordinates[i].latitude, polylineCoordinates[i].longitude),
          pointB : LatLng(polylineCoordinates[i + 1].latitude, polylineCoordinates[i + 1].longitude),
        );
      }
    }
    return totalDistance;
  }



  void writeToFirebase(Marker source, Marker destination, double calculateDistance) {
    Map<String,String> firebaseData = {
      'source' : 'Lat ${source.position.latitude} - Lon ${source.position.longitude}',
      'destination' : 'Lat ${destination.position.latitude} - Lon ${destination.position.longitude}',
      'distance' : calculateDistance.toString(),
    };

    FirebaseFirestore.instance.collection('/Trip').add(firebaseData).then((_) => Fluttertoast.showToast(msg: 'Your Trip is saved successfully' , gravity: ToastGravity.BOTTOM , textColor: Colors.white ,backgroundColor: Colors.green) ,
        onError: (_)=> Fluttertoast.showToast(msg: "Sorry we couldn't save your trip try again later" , gravity: ToastGravity.BOTTOM , textColor: Colors.white ,backgroundColor: Colors.red))
        .timeout((Duration(seconds: 2)), onTimeout: ()=> Fluttertoast.showToast(msg: "Sorry we couldn't save your trip try again later" , gravity: ToastGravity.BOTTOM , textColor: Colors.white ,backgroundColor: Colors.red));
  }


}
