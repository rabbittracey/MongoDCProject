module PlacesHelper
   def to_places value
	  	result = []
	  	if !value.nil?
	      value.each do |v|
	      	result << Place.new(v)
	      end
	    end
	    return result 
   end
end