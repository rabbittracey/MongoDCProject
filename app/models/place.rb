class Place
    include ActiveModel::Model
  	attr_accessor :id, :formatted_address,:location,:address_components
	def initialize(params={})
		@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
		@formatted_address=params[:formatted_address]
		@location = Point.new(params[:geometry][:geolocation])
		@address_components=[]
		if !params[:address_components].nil?
		  params[:address_components].each do |ac|
		    @address_components << AddressComponent.new(ac)
		  end
		end
	end
	def persisted?
		!@id.nil?
	end
	def self.create_indexes
	  Place.collection.indexes.create_one({"geometry.geolocation"=>Mongo::Index::GEO2DSPHERE})
	end
	def self.remove_indexes
	  Place.collection.indexes.drop_one("geometry.geolocation_2dsphere")
	end

	def self.near(point, max_meters=0)
	  self.collection.find(:"geometry.geolocation" => {:$near=>{:$geometry=>point.to_hash,:$maxDistance=>max_meters}})
	end
     
    def near(max_meters=0)
        self.class.to_places(self.class.near(@location, max_meters))
    end

    def self.get_address_components( sort={:_id => 1}, offset=0, limit=999)
        self.collection.find.aggregate([{:$project=> {
                 :_id => 1, :address_components=> 1, :formatted_address => 1, 'geometry.geolocation': 1}},
       {:$unwind=>'$address_components'},{:$sort=>sort},{:$skip=> offset},{:$limit=>limit}])
       
    end
    def self.find_ids_by_country_code country_code 
    	result = collection.find().aggregate([
    		    {:$match=>{"address_components.short_name"=>country_code}},
				{:$project=>{ :_id=>1}}
			   ])
		return result.to_a.map {|h| h[:_id].to_s}
    end

    def self.get_country_names
		result = collection.find().aggregate([
				{:$project=>{ "address_components.long_name"=>1, "address_components.types"=>1}},
				{:$unwind=>"$address_components"},
				{:$match=>{"address_components.types"=>"country"}},
				{:$group=>{ :_id=>'$address_components.long_name'}}])
		return result.to_a.map {|h| h[:_id]}
	end




	def self.find_by_short_name short_name
	    result = self.collection.find( { 'address_components.short_name' => short_name })
	    return result.nil? ? nil : result
	end 
	def self.to_places value
	  	result = []
	  	if !value.nil?
	      value.each do |v|
	      	result << Place.new(v)
	      end
	    end
	    return result 
   end

    def self.find id_string
     id = BSON::ObjectId.from_string(id_string)
	 doc=collection.find(:_id=>id).first
	 return doc.nil? ? nil : Place.new(doc)
	end 

	def self.all(offset=0, limit=100)
	    result=collection.find().skip(offset)
	    result=result.limit(limit) if !limit.nil?
	    final_result= []
	    if !result.nil?
	      result.each do |r|
	      	final_result << Place.new(r)
	      end
	    end
	    return final_result
	end

	def self.mongo_client
		Mongoid::Clients.default
	end
	def self.collection
		self.mongo_client['places']
	end
  def self.load_all(file)
    data = file.read
    hash=JSON.parse(data)
    places=Place.collection
    places.insert_many(hash)
  end
  def destroy
    self.class.collection
              .find(_id:BSON::ObjectId.from_string(@id))
              .delete_one   
  end  
  
  def photos(offset=0, limit=1000)

  	result=Photo.find_photos_for_place(self.id).skip(offset)
	    result=result.limit(limit) if !limit.nil?
	    final_result= []
	    if !result.nil?
	      result.each do |r|
	      	final_result << Photo.new(r)
	      end
	    end
	    return final_result
    end 
end



