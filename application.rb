QUEUE = MemCache.new(Merb.config[:queue])


class Action
  include DataMapper::Resource
  
  property :id, Serial
  property :event, String
  property :kind, String
  property :ref, Integer
  property :extra, String
end

class Entry
  include DataMapper::Resource
  
  property :id, Serial
  property :refid, String
  property :data, String
  property :source, String
  
  after :save, :push_to_queue
  
  is :state_machine, :initial => :new do
    state :new #, :enter => proc {|obj| Action.create(:event => "new", :kind => 'entry', :ref => obj.key)}
    state :accepted
    state :rejected
    state :passed
    
    event :accept do
      transition :from => :new, :to => :accepted
      transition :from => :passed, :to => :accepted
      transition :from => :rejected, :to => :accepted
    end
    
    event :reject do
      transition :from => :new, :to => :rejected
      transition :from => :passed, :to => :rejected
      transition :from => :accepted, :to => :rejected
    end
  end
  
  def push_to_queue(queues = ['stanford', 'shallow', 'question'])
    json = {'key' => self.key[0].to_s, 'question' => self.data }.to_json
    
    begin
      queues.each do |q|
        QUEUE.set(q, json, 0, true)
      end
      
    rescue Exception => e
      
    end
    
  end
  
end

class Category
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  property :cid, String
  property :last_visited, DateTime
end

class Question
  include HTTParty
  format :xml
  
  # use :name to find by name or :cid to find by id
  def self.find_by_category(options = {})
    query = { :appid => Merb.config[:yahoo_appid], :results => 50, :start => rand(50) * 50 }
    if options[:cid]
      query[:category_id] = options[:cid]
    else
      query[:category_name] = options[:name]
    end
        
    get('http://answers.yahooapis.com/AnswersService/V1/getByCategory', :query => query)
  end
end

class Siphon < Merb::Controller

  def _template_location(action, type = nil, controller = controller_name)
    controller == "layout" ? "layout.#{action}.#{type}" : "#{action}.#{type}"
  end

  def index
    @new = Entry.all(:state => :new)
    @accepted = Entry.all(:state => :accepted)
    @rejected = Entry.all(:state => :rejected)
    render
  end
  
  def accepted
    provides :json, :xml
    
    @accepted = Entry.all(:state => :accepted)
    @rejected = Entry.all(:state => :rejected)
    display @accepted
  end

  def load
    if params.has_key? :state
      entries = Entry.all(:state => params[:state])
    else
      entries = Entry.all(:state => :new)

      if entries.length < 50
        more
      end

      entries = Entry.all(:state => :new)
    end
    
    
    entries.to_json
  end
  
  def accept
    entry = Entry.get(params[:id])
    
    entry.accept!
    
    entry.save
    
    entry.to_json
  end
  
  def reject
    entry = Entry.get(params[:id])
    
    entry.reject!
    
    entry.save
    
    entry.to_json
  end
  
  def couch
    db = CouchRest.database!(Merb.config[:couchdb])
    @entry = Entry.get(params[:id])
    begin
      @doc = db.get(params[:id])
    rescue RestClient::ResourceNotFound => e
      @doc = nil
    end
    
    if !@doc or !is_complete? @doc
      @entry.push_to_queue
      sleep 5
      @doc = db.get(params[:id])
    end
    
    render
  end
  
  def sweep
    ids = Entry.all.collect {|e| e.key[0].to_s }
    db = CouchRest.database!(Merb.config[:couchdb])
    buffer_size = 10
    
    (0..(ids.length.to_f / buffer_size).ceil - 1).each do |i|
      docs = db.get_bulk(ids[i * buffer_size..i * buffer_size + buffer_size - 1])
      docs["rows"].each do |doc|
        if doc.include? "error"
          Entry.get(doc["key"]).push_to_queue
        elsif !is_complete? doc["doc"]
          Entry.get(doc["key"]).push_to_queue
        end
      end
      
    end
    
  end
  
  private
  
  def more
    questions = if params[:category]
      if params[:category] ==~ /\d+/
        Question.find_by_category(:cid => params[:category])
      else
        Question.find_by_category(:name => params[:category])
      end
    else
      Question.find_by_category(:cid => Category.get(1 + rand(Category.count)).cid)
    end

    questions['ResultSet']['Question'].each do |q|
      if not Entry.first(:refid => q['id'])
        Entry.create(:refid => q['id'], :data => q['Subject'], :source => q['Link'])
      end
    end
    
  end
  
end

def is_complete? doc
  tags = Set.new("stanford", "shallow", "question")
  return false unless doc.include? "tags" and doc["tags"] and Set.new(doc["tags"]) == tags
  
  return tags.all? {|t| !doc[t].nil? }
  
end