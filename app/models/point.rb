class Point
	# include ActiveModel::Model
	 attr_accessor :longitude,:latitude
	 def to_hash
	  hash = Hash.new
	  hash[:type] = "Point"
	  hash[:coordinates] = []
	  hash[:coordinates] << @longitude
	  hash[:coordinates] << @latitude
	  return hash
	end
	 def initialize(params={})
	 	if params[:coordinates].nil?
	 		@latitude = params[:lat]
	 		@longitude = params[:lng]

	 	else
	 		@latitude = params[:coordinates][1]
	 		@longitude = params[:coordinates][0]
	 	end
	end
end



