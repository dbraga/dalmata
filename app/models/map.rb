require 'rubygems'
require 'json'
require 'net/http'

class Point
    def initialize( *coords )
        @coords = coords.map{|x| x.to_f}
    end

    def size
        @coords.size
    end

    def []( index )
        @coords[index]
    end

    def []= ( index, x )
        @coords[index] = x
    end

    def self.random( n = 2 )
        Point.new( *(1..n).map{ 0.5 - rand } )
    end

    def +(p)
        return Point.new( *(0...size).map{|i| @coords[i] + p[i]} )
    end

    def -(p)
        return Point.new( *(0...size).map{|i| @coords[i] - p[i]} )
    end

    def *(a)
        return Point.new( *@coords.map{|x| x * a} )
    end

    def /(a)
        return Point.new( *@coords.map{|x| x / a} )
    end

    # calculate the inner product if this point with p
    def ip(p)
        (0...size).inject(0) { |sum, i| sum + @coords[i] * p[i] }
    end

    def to_s
        "(#{@coords.join(', ')})"
    end
end

class Circle < Struct.new(:center, :radius)
    def to_s
        "{center:#{center}, radius:#{radius}}"
    end
end



class Map < ActiveRecord::Base
  # attr_accessible :title, :body


  def self.test(string)
  	puts string
  end

def self.generate_samples(n, dim = 2)
    (1..n).map { Point.random(dim) }
end


# calculate value and subgradient of
# f(x,y) = max{(x-x_i)^2 + (y-y_i)^2: (x_i,y_i) in points}
def self.evaluate( m, points )
    y_big = nil
    grad = nil
    points.each do |p|
        d = (m - p)
        y = d.ip( d ) # y = sum (m_i-p_i)^2
        if y_big.nil? or y > y_big
            y_big = y
            grad = d*2
        end
    end

    return [y_big, grad]
end

# perform simple subgradient algorithm
# with given starting-point and number of iterations
def self.encircle( points,
              x_start = Point.new( *([0]*points[0].size) ),
              max_iter = 100 )
    x = x_start
    y, g = nil, nil

    for k in 1..max_iter do
        y, g = evaluate( x, points )
        x = x - g/k
    end

    return Circle.new(x, Math.sqrt(y))
end


def self.json(query, rows, title, snippet)
   url ="http://localhost:8080/apache-solr-3.6.1/clustering?q="+query+"&rows="+rows+"&indent=on&carrot.title="+title+"&carrot.snippet="+snippet+"&carrot.produceSummary=false&wt=json&fl=id,price_i,latitude_f,longitude_f,geohash_s,state_s"
   
			puts "\n\n\n\n\n\n\n\n\n***************** " + url
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
puts "\n\n\n\n\n\n\n\n\n***************** " + rows
result = json(query,rows,title, snippet)
clusters = result["clusters"]
solrDocs = result["response"]["docs"]
output = ""

output = output + "map.setView(new L.LatLng("+solrDocs.first["latitude_f"].to_s+","+solrDocs.first["longitude_f"].to_s+"), 12);
var baseLayer = new L.TileLayer(cloudmadeUrl, { attribution: cloudmadeAttribution});
baseLayer.addTo(map);" + "\n"

clusters.each do |cluster|
   output = "\n" + output +  "// Cluster: "+cluster["labels"].first + "\n"
   points = Array.new
   cluster["docs"].each do |doc|
      solrDocs.each do |solrDoc|
         if solrDoc["id"].eql?(doc)
            points << Point.new(solrDoc["latitude_f"],solrDoc["longitude_f"].to_s)
            output = "\n" + output +  "var marker = new L.Marker(["+solrDoc["latitude_f"].to_s+", "+solrDoc["longitude_f"].to_s+"]);
                  marker.bindPopup('Cluster: "+cluster["labels"].first.delete("'")+"<br><b> Price: "+solrDoc["price_i"].to_s+"$</b>').openPopup();
                  marker.addTo(map);" + "\n"
         end       
      end
   end

   circle = encircle(points)
   color = [:red, :blue, :yellow, :orange, :grey, :black, :green, :violet, :brown].sample.to_s

   output = "\n" + output +  "var circle = L.circle(["+circle.center.to_s.delete("(").delete(")")+"], "+((circle.radius.to_s.delete("(").delete(")")).to_f*100000).to_s+", {
    color: '"+color+"',
    fillColor: '"+color+"',
    fillOpacity: 0.5
}).addTo(map); " + "\n"
end

output
end
end
