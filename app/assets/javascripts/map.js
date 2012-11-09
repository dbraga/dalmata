function getJSON(url,firstTime){
    $.getJSON(url,
     function(result){ 
        // var coordinates = splitCoordinate(result["clusters"][0]["docsPoints"][0]);
        // var lat = coordinates[0];
        // var lng = coordinates[1];
        // if (firstTime){
        // map.setView(new L.LatLng(lng,lat), 9);
        // }

        // map.setView(new L.LatLng(37.729453,-122.447485),currentZoom);



        var baseLayer = new L.TileLayer(truliaUrl, { attribution: truliaAttribution});
        baseLayer.addTo(map);
        markersArray = new Array();
        for (var i=0; i<result["clusters"].length; i++){
            markersArray[i] = new L.MarkerClusterGroup({title: 'test'});
            for (var j=0; j< result["clusters"][i]["docsPoints"].length; j++){
                var c = splitCoordinate(result["clusters"][i]["docsPoints"][j])
                var marker = new L.Marker(new L.LatLng(c[1],c[0]), { title: ''}); 
                // marker.bindPopup('#{clusterName}');
                markersArray[i].addLayer(marker);
            }
            map.addLayer(markersArray[i]);
        }
});}

function getJSON2(url){
    $.getJSON(url,
     function(result){ 

        var coordinates = splitCoordinate(result["clusters"][0]["docsPoints"][0]);
        var lat = coordinates[0];
        var lng = coordinates[1];
        // map.setView(new L.LatLng(lng,lat), 9);

        var baseLayer = new L.TileLayer(truliaUrl, { attribution: truliaAttribution});
        baseLayer.addTo(map);
        
        // markersArray = new Array();

        for (var i=0; i<result["clusters"].length; i++){
            markers = new L.MarkerClusterGroup({title: 'test'});
            for (var j=0; j< result["clusters"][i]["docsPoints"].length; j++){
                var c = splitCoordinate(result["clusters"][i]["docsPoints"][j])
                var marker = new L.Marker(new L.LatLng(c[1],c[0]), { title: ''}); 
                // marker.bindPopup('#{clusterName}');
                markers.addLayer(marker);
            }
            
        }
        map.addLayer(markers);
});}



var map ;
var markers;
var truliaUrl;
var markersArray;
var initialZoomLevel = 9;
var previousZoom;
var currentZoom = initialZoomLevel;

var q ;
var carrot_title ;
var carrot_snippet ;

var localip = "10.1.25.33";

function getUrlVars() {
    var vars = {};
    var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
        vars[key] = value;
    });
    return vars;
}


function removeMarkers(){
   
        if ( markersArray.length > 0 ){
             //remove all previous layers-markers
            for (var i=0; i< markersArray.length; i++){
                map.removeLayer(markersArray[i]);
            }          
        }


        if (markers != undefined){
            map.removeLayer(markers);
        }




}

function savePreviousZoom(){
    previousZoom = map.getZoom();
}

function saveCurrentZoom(){
    currentZoom = map.getZoom();
}


function splitCoordinate(coordinate){
    return coordinate.replace('(','').replace(')','').split(',');
}

function zoomController(){
    console.log('Current zoom: '+map.getZoom());
    console.log('Prev zoom: '+previousZoom);
    if ( map.getZoom() >= 10){
        // Convex Hull

        // If previous zoom was already a convex hull one, we don't need to call again Solr
        if ( previousZoom < 10 ){
            // We need to call Solr again
            removeMarkers();

            console.log(map.getZoom());
            q = getUrlVars()["query"];
            carrot_title ="geohash_s";
            carrot_snippet ="neighborhoodDisplay_s";
            url = "http://"+localip+":8080/apache-solr-3.6.1/clustering?q="+q+"&rows=400&indent=on&fl=clusters&carrot.title="+carrot_title+"&carrot.snippet="+carrot_snippet+"&carrot.produceSummary=false&wt=json&json.wrf=?";
            getJSON2(url);

        }


}

    if (map.getZoom()==9){
    console.log('9!');

    removeMarkers();

    q = 'state_s:CA, city_s:"SAN FRANCISCO"';
    carrot_title ="countyDisplay_s";
    carrot_snippet ="countyDisplay_s";
    url = "http://"+localip+":8080/apache-solr-3.6.1/clustering?q="+q+"&rows=400&indent=on&fl=clusters&carrot.title="+carrot_title+"&carrot.snippet="+carrot_snippet+"&carrot.produceSummary=false&wt=json&json.wrf=?";
    getJSON(url,false);

    }

}

$(document).ready(function() {
  // Handler for .ready() called.
    truliaUrl = "http://mt1.googleapis.com/vt?lyrs=m@183101440&src=apiv3&hl=en-US&x={x}&y={y}&z={z}&apistyle=s.t%3A1%2Cs.t%3A17%7Cp.v%3Asimplified%2Cs.t%3A18%7Cp.v%3Asimplified%2Cs.t%3A5%7Cp.s%3A-10%2Cs.t%3A2%7Cp.v%3Aoff%2Cs.t%3A40%7Cp.s%3A-10%7Cp.l%3A30%7Cp.v%3Asimplified%2Cs.t%3A3%7Cp.s%3A-100%2Cs.t%3A49%7Cs.e%3Ag%7Cp.h%3A%235EAB1F%2Cs.t%3A49%7Cp.v%3Asimplified%2Cs.t%3A50%7Cp.s%3A-100%7Cp.l%3A20%2Cs.t%3A50%7Cp.v%3Aon%2Cs.t%3A51%7Cp.v%3Aon%2Cs.t%3A4%7Cp.s%3A-100%2Cs.t%3A6%7Cp.h%3A%230089CF%7Cp.s%3A-50%7Cp.l%3A30%2Cs.t%3A21%7Cp.v%3Aon&s=Ga&style=api%7Csmartmaps'",
    truliaAttribution = "<a href='http://mapbox.com/about/maps' target='_blank'>Terms & Feedback</a>" ,
    trulia = new L.TileLayer(truliaUrl, { attribution: truliaAttribution}),
    latlng = new L.LatLng(37.729453,-122.447485);

    map = new L.Map('map', {center: latlng, zoom: initialZoomLevel, minZoom: 9, maxZoom: 16, layers: [trulia]});

    // map.on('zoomstart',removeMarkers)
    map.on('zoomstart',savePreviousZoom);
    map.on('zoomend', zoomController);

    // map.on('zoomend',saveCurrentZoom);

    // FIRST CALL
    // COUNTY CLUSTERING ?

    //Override normal query 
    q = getUrlVars()["query"];
    carrot_title ="countyDisplay_s";
    carrot_snippet ="countyDisplay_s";
    url = "http://"+localip+":8080/apache-solr-3.6.1/clustering?q="+q+"&rows=400&indent=on&fl=clusters&carrot.title="+carrot_title+"&carrot.snippet="+carrot_snippet+"&carrot.produceSummary=false&wt=json&json.wrf=?";
    getJSON(url,true);

    console.log("after first call zoom: " + map.getZoom() );

});


// 

