module PhotoHelper
   def find_nearest_place_id maximum_distance
	  	collection = Place.near(@location, maximum_distance).aggregate([
																	    {:$limit=>1},
																	    {:$project=>{_id: 1}}
																	  ])
	  	collection.nil? ? nil : collection.first[:_id]
   end
end