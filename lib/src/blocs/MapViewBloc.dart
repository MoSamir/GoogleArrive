import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_drive/src/utilities/NetworkUtility.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
abstract class MapViewEvents {}
class GetUserLocation extends MapViewEvents{}

abstract class MapViewStates {}

class MapViewLoadingState extends MapViewStates{}
class MapViewLoadedState extends MapViewStates{
  final LatLng userLocation ;
  MapViewLoadedState({this.userLocation});
}
class MapViewErrorState extends MapViewStates{
  final Error error;
  MapViewErrorState(this.error);

}


class MapViewBloc extends Bloc<MapViewEvents , MapViewStates>{
  MapViewBloc(MapViewStates initialState) : super(initialState ?? MapViewLoadingState());

  @override
  Stream<MapViewStates> mapEventToState(MapViewEvents event) async*{
    bool isUserConnected = await NetworkUtility.isConnected();
    if(isUserConnected == false){
      yield MapViewErrorState(Error.NetworkFailure);
      return ;
    }
    if(event is GetUserLocation){
      yield* _handleUserLocation();
      return;
    }
  }

  Stream<MapViewStates> _handleUserLocation() async*{
    yield MapViewLoadingState();
    LocationData currentLocation;
    LatLng currentPosition = LatLng(0.0, 0.0);
    var location = new Location();
    try {
      currentLocation = await location.getLocation().timeout(Duration(seconds: 5));
      currentPosition = LatLng(currentLocation.latitude, currentLocation.longitude);
    } on Exception {
      currentLocation = null;
    }

    yield MapViewLoadedState(userLocation: currentPosition);
        return ;

  }
}

enum Error {
  NetworkFailure ,
  LocationFailure ,
}