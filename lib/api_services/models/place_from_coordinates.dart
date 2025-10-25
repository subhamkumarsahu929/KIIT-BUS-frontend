

import 'dart:convert';

PlaceFromCoordinates placeFromCoordinatesFromJson(String str) => PlaceFromCoordinates.fromJson(json.decode(str));

String placeFromCoordinatesToJson(PlaceFromCoordinates data) => json.encode(data.toJson());

class PlaceFromCoordinates {
    PlusCode plusCode;
    List<Result> results;
    String status;

    PlaceFromCoordinates({
        required this.plusCode,
        required this.results,
        required this.status,
    });

    factory PlaceFromCoordinates.fromJson(Map<String, dynamic> json) => PlaceFromCoordinates(
        plusCode: PlusCode.fromJson(json["plus_code"]),
        results: List<Result>.from(json["results"].map((x) => Result.fromJson(x))),
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "plus_code": plusCode.toJson(),
        "results": List<dynamic>.from(results.map((x) => x.toJson())),
        "status": status,
    };
}

class PlusCode {
    String compoundCode;
    String globalCode;

    PlusCode({
        required this.compoundCode,
        required this.globalCode,
    });

    factory PlusCode.fromJson(Map<String, dynamic> json) => PlusCode(
        compoundCode: json["compound_code"],
        globalCode: json["global_code"],
    );

    Map<String, dynamic> toJson() => {
        "compound_code": compoundCode,
        "global_code": globalCode,
    };
}

class Result {
    List<AddressComponent> addressComponents;
    String formattedAddress;
    Geometry geometry;
    List<NavigationPoint>? navigationPoints;
    String placeId;
    List<String> types;
    PlusCode? plusCode;

    Result({
        required this.addressComponents,
        required this.formattedAddress,
        required this.geometry,
        this.navigationPoints,
        required this.placeId,
        required this.types,
        this.plusCode,
    });

    factory Result.fromJson(Map<String, dynamic> json) => Result(
        addressComponents: List<AddressComponent>.from(json["address_components"].map((x) => AddressComponent.fromJson(x))),
        formattedAddress: json["formatted_address"],
        geometry: Geometry.fromJson(json["geometry"]),
        navigationPoints: json["navigation_points"] == null ? [] : List<NavigationPoint>.from(json["navigation_points"]!.map((x) => NavigationPoint.fromJson(x))),
        placeId: json["place_id"],
        types: List<String>.from(json["types"].map((x) => x)),
        plusCode: json["plus_code"] == null ? null : PlusCode.fromJson(json["plus_code"]),
    );

    Map<String, dynamic> toJson() => {
        "address_components": List<dynamic>.from(addressComponents.map((x) => x.toJson())),
        "formatted_address": formattedAddress,
        "geometry": geometry.toJson(),
        "navigation_points": navigationPoints == null ? [] : List<dynamic>.from(navigationPoints!.map((x) => x.toJson())),
        "place_id": placeId,
        "types": List<dynamic>.from(types.map((x) => x)),
        "plus_code": plusCode?.toJson(),
    };
}

class AddressComponent {
    String longName;
    String shortName;
    List<String> types;

    AddressComponent({
        required this.longName,
        required this.shortName,
        required this.types,
    });

    factory AddressComponent.fromJson(Map<String, dynamic> json) => AddressComponent(
        longName: json["long_name"],
        shortName: json["short_name"],
        types: List<String>.from(json["types"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "long_name": longName,
        "short_name": shortName,
        "types": List<dynamic>.from(types.map((x) => x)),
    };
}

class Geometry {
    NortheastClass location;
    String locationType;
    Viewport viewport;
    Viewport? bounds;

    Geometry({
        required this.location,
        required this.locationType,
        required this.viewport,
        this.bounds,
    });

    factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
        location: NortheastClass.fromJson(json["location"]),
        locationType: json["location_type"],
        viewport: Viewport.fromJson(json["viewport"]),
        bounds: json["bounds"] == null ? null : Viewport.fromJson(json["bounds"]),
    );

    Map<String, dynamic> toJson() => {
        "location": location.toJson(),
        "location_type": locationType,
        "viewport": viewport.toJson(),
        "bounds": bounds?.toJson(),
    };
}

class Viewport {
    NortheastClass northeast;
    NortheastClass southwest;

    Viewport({
        required this.northeast,
        required this.southwest,
    });

    factory Viewport.fromJson(Map<String, dynamic> json) => Viewport(
        northeast: NortheastClass.fromJson(json["northeast"]),
        southwest: NortheastClass.fromJson(json["southwest"]),
    );

    Map<String, dynamic> toJson() => {
        "northeast": northeast.toJson(),
        "southwest": southwest.toJson(),
    };
}

class NortheastClass {
    double lat;
    double lng;

    NortheastClass({
        required this.lat,
        required this.lng,
    });

    factory NortheastClass.fromJson(Map<String, dynamic> json) => NortheastClass(
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "lat": lat,
        "lng": lng,
    };
}

class NavigationPoint {
    NavigationPointLocation location;

    NavigationPoint({
        required this.location,
    });

    factory NavigationPoint.fromJson(Map<String, dynamic> json) => NavigationPoint(
        location: NavigationPointLocation.fromJson(json["location"]),
    );

    Map<String, dynamic> toJson() => {
        "location": location.toJson(),
    };
}

class NavigationPointLocation {
    double latitude;
    double longitude;

    NavigationPointLocation({
        required this.latitude,
        required this.longitude,
    });

    factory NavigationPointLocation.fromJson(Map<String, dynamic> json) => NavigationPointLocation(
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
    };
}
