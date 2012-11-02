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
  if lastCluster.first.second.eql?(["Other Topics"])
    result["clusters"].last["docs"]
  else
    []
  end
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

def self.results(query = "city_s:%22SAN%20FRANCISCO%22", rows = "100", title = "geohash_s", snippet="neighborhoodDisplay_s")
  result = json(query,rows,title, snippet)
  clusters = result["clusters"]
  solrDocs = result["response"]["docs"]
  # Setting the map view
  output = "map.setView(new L.LatLng("+solrDocs.first["latitude_f"].to_s+","+solrDocs.first["longitude_f"].to_s+"), 12);
  var baseLayer = new L.TileLayer(truliaUrl, { attribution: truliaAttribution});
  baseLayer.addTo(map);
  var markers = new L.MarkerClusterGroup({ maxClusterRadius: 200 });" + "\n"
  # output clusters
  clusters.each do |cluster|
     output = "\n" + output +  "// Cluster: "+cluster["labels"].first + "\n"
     cluster["docs"].each do |doc|
        solrDocs.each do |solrDoc|
           if solrDoc["id"].eql?(doc) && (!solrDoc["latitude_f"].to_s.blank?) && (!solrDoc["longitude_f"].to_s.blank?)
            output = "\n" + output + 
            "var marker = new L.Marker(new L.LatLng("+solrDoc["latitude_f"].to_s + " , " + solrDoc["longitude_f"].to_s+"), { title: '"+cluster["labels"].first+"'}); 
            marker.bindPopup('"+cluster["labels"].first+"');
            markers.addLayer(marker);\n"
           end       
        end
     end
  end
  output + "map.addLayer(markers);"
  end
end
