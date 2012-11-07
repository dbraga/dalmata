require 'rubygems'
require 'json'
require 'net/http'

class Map < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.test(string)
  	puts string
  end

def self.otherTopics(query, rows, title, snippet)
  result = json(query,rows,title, snippet)
  lastCluster = result["clusters"].last
  result['clusters'].last["docsCount"]
end

def self.json(query, rows, title, snippet)
   url ="http://localhost:8080/apache-solr-3.6.1/clustering?q="+query+"&rows="+rows+"&indent=on&carrot.title="+title+"&carrot.snippet="+snippet+"&carrot.produceSummary=false&wt=json&fl=id,price_i,latitude_f,longitude_f,geohash_s,state_s"
   resp = Net::HTTP.get_response(URI.parse(URI.encode(url.strip)))
   data = resp.body
   # we convert the returned JSON data to native Ruby
   # data structure - a hash
   result = JSON.parse(data)
   # if the hash has 'Error' as a key, we raise an error
   if result.has_key? 'Error'
      raise "web service error"
   end
   return result
end

def self.reverseCoordinate(c)
  "("+c.delete("(").delete(")").delete(" ").split(",")[1] +","+ c.delete("(").delete(")").delete(" ").split(",")[0]+ ")"
end

def self.results(query = "city_s:%22SAN%20FRANCISCO%22", rows = "100", title = "geohash_s", snippet="neighborhoodDisplay_s")
  result = json(query,rows,title, snippet)
  clusters = result["clusters"]
  solrDocs = result["response"]["docs"]
  # Setting the map view
  output = "
    var initialZoomLevel = 9;

    map.setView(new L.LatLng("+solrDocs.first["latitude_f"].to_s+","+solrDocs.first["longitude_f"].to_s+"), initialZoomLevel);
    var baseLayer = new L.TileLayer(truliaUrl, { attribution: truliaAttribution});
    baseLayer.addTo(map);"
    
       output +="map.on('zoomstart', function (a) {
                   console.log(map.getZoom());
                });\n"  
  # output clusters
  
  clusters.each do |cluster|
    # cluster = clusters.first
    clusterName = cluster["labels"].first.delete("'")
    if !clusterName.eql?("Other Topics")
      clusterCentroid = reverseCoordinate(cluster["docsCentroid"])
      docsPoints = cluster["docsPoints"]
      output += "// Cluster: #{clusterName} \n"
      output += "// Count: #{cluster["docsCount"]} \n"
      output += "// Docs Centroid: #{cluster["docsCentroid"]} \n"
      output += "// Range Price: #{cluster["rangePrice"]} \n"
      # output +="var markers = new L.MarkerClusterGroup({ maxClusterRadius: 80 });\n"
      # output +="var markers = new L.MarkerClusterGroup();\n"
      # output +="var markers = new L.MarkerClusterGroup({ options: {
      #     iconCreateFunction: 
      #       function(cluster) {
      #         return new L.DivIcon({ html: '<b></b>' });
      #       }
      #     }
      #   });\n"

      output +="var markers = new L.MarkerClusterGroup({title: 'test'});"
      docsPoints.each do |d|
        reversePoint = reverseCoordinate(d)
        output += "var marker = new L.Marker(new L.LatLng#{reversePoint}, { title: '#{clusterName}'}); 
        marker.bindPopup('#{clusterName}');
        markers.addLayer(marker);\n"
      end
       output += "map.addLayer(markers);\n"
    end
   

  end

    


  
  output
  end
end
