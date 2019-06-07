class Photo
	require 'exifr/jpeg'
	attr_accessor :id, :location
	attr_writer :contents

	def place
	  Place.find(@place)  if @place.is_a? BSON::ObjectId
	end
	def place=(value)
	    @place = value                                if value.is_a? BSON::ObjectId
	    @place = BSON::ObjectId.from_string(value)    if value.is_a? String
	    @place = BSON::ObjectId.from_string(value.id) if value.is_a? Place 
	end

	def self.mongo_client
		Mongoid::Clients.default
	end
	def initialize(params={})
		if params.present?
	      self.id       = params[:_id] ? params[:_id].to_s : params[:id]
	      self.location = params[:metadata].nil? ? Point.new : Point.new(params[:metadata][:location])
	      self.place    = params[:metadata][:place]
	    end	
	end
	def persisted?
		!@id.nil?
	end
	# def save 
	# 	gps = EXIFR::JPEG.new(self.contents).gps
	# 	self.location = Point.new({:lat => gps.latitude, :lng => gps.longitude })
	# 	description = {}
	# 	description["content_type"] = "image/jpeg"
	# 	grid_file = Mongo::Grid::File.new(self.contents.read, description)


	#     result=self.class.collection
	#               .insert_one(_id:@id, first_name:@first_name,last_name:@last_name,number:@number,gender:@gender,group:@group,secs:@secs)
	#     @id=result.inserted_id
	# end

	def save
	  attributes = {}
      attributes[:metadata] = {}
	  if !persisted?
		gps = EXIFR::JPEG.new(@contents).gps if !@contents.nil?
		self.location = Point.new({:lat => gps.latitude, :lng => gps.longitude}) if !gps.nil?
		@contents.rewind if !@contents.nil?
		description = {}
		metadata = {}
		metadata[:location] = @location.to_hash if @location
		metadata[:place] = BSON::ObjectId.from_string(place.id) if place.is_a? Place
		description[:metadata] = metadata
	    description["content_type"] = "image/jpeg"
	    grid_file = Mongo::Grid::File.new(@contents.read,description) if !@contents.nil?
	    @id = self.class.mongo_client.database.fs.insert_one(grid_file).to_s if !grid_file.nil?
	   else
	   	attributes[:metadata][:location] = @location.to_hash
	   	attributes[:metadata][:place] = BSON::ObjectId.from_string(place.id) if place.is_a? Place
        self.class.mongo_client.database.fs.find(:_id=> BSON::ObjectId.from_string(@id)).update_one(attributes)
	   end
	end
	def self.all(offset=0, limit=1069.4 * 10000)
	    result=self.mongo_client.database.fs.find().skip(offset)
	    result=result.limit(limit) if !limit.nil?
	    final_result= []
	    if !result.nil?
	      result.each do |r|
	      	final_result << Photo.new(r)
	      end
	    end
	    return final_result
	end
	def self.find id_string
	    id = BSON::ObjectId.from_string(id_string)
		doc=self.mongo_client.database.fs.find(:_id=>id).first
		return doc.nil? ? nil : Photo.new(doc)
	end 
    def contents
      Photo.mongo_client.database.fs.find_one(:_id=>BSON::ObjectId.from_string(self.id)).data
    end
    def destroy
	  Photo.mongo_client.database.fs.find(_id:BSON::ObjectId.from_string(@id.to_s)).delete_one   
	end  
	def find_nearest_place_id maximum_distance
	  	collection = Place.near(@location, maximum_distance).limit(1)
	  	collection.nil? ? nil : collection.first[:_id]
    end
 
    def self.find_photos_for_place id_string
      id = BSON::ObjectId.from_string(id_string)
	  result=Photo.mongo_client.database.fs.find(:"metadata.place"=>id)
	  return result
	end
end



