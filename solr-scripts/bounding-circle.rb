# extends point-class with an arbitrary dimension
# and simple vector-operations
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

def generate_samples(n, dim = 2)
    (1..n).map { Point.random(dim) }
end


# calculate value and subgradient of
# f(x,y) = max{(x-x_i)^2 + (y-y_i)^2: (x_i,y_i) in points}
def evaluate( m, points )
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
def encircle( points,
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

puts encircle( generate_samples(10000, 3) )
