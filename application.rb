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
    query = { :appid => Merb.config[:yahoo_appid] }
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
    render
  end
  
  def load
    questions = if params[:category]
      if params[:category] ==~ /\d+/
        Question.find_by_category(:cid => params[:category])
      else
        Question.find_by_category(:name => params[:category])
      end
    else
      Question.find_by_category(:cid => Category.first)
    end
    
    questions.to_json
  end

  def foo
    render
  end
  
end