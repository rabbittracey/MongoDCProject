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


	# def persisted?
	# 	!@id.nil?
	# end
	# def created_at
	# 	nil
	# end
	# def updated_at
	# 	nil
	# end

	
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

	# def self.all(prototype={}, sort={:number => 1}, offset=0, limit=nil)
 #    #map internal :population term to :pop document term
 #    tmp = {} #hash needs to stay in stable order provided
 #    sort.each {|k,v| 
 #      tmp[k] = v  if [:number,:first_name,:last_name,:gender,:group,:secs].include?(k)
 #    }
 #    sort=tmp

 #    Rails.logger.debug {"getting all racers, prototype=#{prototype}, sort=#{sort}, offset=#{offset}, limit=#{limit}"}

 #    result=collection.find(prototype)
 #          .projection({_id:true, first_name:true, last_name:true, number:true,gender: true,group:true,secs:true})
 #          .sort(sort)
 #          .skip(offset)
 #    result=result.limit(limit) if !limit.nil?
 #    return result
 #  end
 #  def self.find id
 #  	result=collection.find(:_id=>BSON::ObjectId.from_string(id))
 #                    .projection({_id:true, first_name:true, last_name:true, number:true,gender: true,group:true,secs:true})
 #                    .first
 #  	return result.nil? ? nil : Racer.new(result)
 #  end

 #  def self.paginate(params)
 #    page=(params[:page] ||= 1).to_i
 #    limit=(params[:per_page] ||= 30).to_i
 #    offset=(page-1)*limit
 #    sort=params[:sort] ||= {}

 #    #get the associated page of Zips -- eagerly convert doc to Zip
 #    racers=[]
 #    all({},{}, offset, limit).each do |doc|
 #      racers << Racer.new(doc)
 #    end

 #    #get a count of all documents in the collection
 #    total=all({},{}, 0, 1).count
    
 #    WillPaginate::Collection.create(page, limit, total) do |pager|
 #      pager.replace(racers)
 #    end    
 #  end
  
 #  def save 
 #    Rails.logger.debug {"saving #{self}"}

 #    result=self.class.collection
 #              .insert_one(_id:@id, first_name:@first_name,last_name:@last_name,number:@number,gender:@gender,group:@group,secs:@secs)
 #    @id=result.inserted_id
 #  end
 #  def update(params)
	# @number=params[:number].to_i
	# @first_name=params[:first_name]
	# @last_name=params[:last_name]
	# @secs=params[:secs].to_i
 #    @gender = params[:gender]
 #    @group = params[:group]
	# params.slice!(:number, :first_name, :last_name, :gender, :group, :secs) 
	# self.class.collection
	# 		  .find(_id:BSON::ObjectId.from_string(@id.to_s))
	# 		  .update_one(first_name:@first_name,last_name:@last_name,number:@number,gender:@gender,group:@group,secs:@secs)

 #  end
 #  def destroy
 #    Rails.logger.debug {"destroying #{self}"}

 #    self.class.collection
 #              .find(_id:BSON::ObjectId.from_string(@id.to_s))
 #              .delete_one   
 #  end  

end



