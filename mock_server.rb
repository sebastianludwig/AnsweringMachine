require 'partials'

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, "sqlite3://#{File.dirname(File.expand_path(__FILE__))}/server.db")
DataMapper::Model.raise_on_save_failure = true  # globally across all models

class Response
  include DataMapper::Resource
  property :id, Serial
  property :path, String, :index => :path
  property :http_status, Integer, :default => 200
  property :resend, Boolean, :default => false
  #property :forward, String
  #property :conent_type, String
  property :body, String
  property :requested_at, DateTime
  
  default_scope(:default).update(:order => [:requested_at.desc])
  
  def self.sent
    all(:conditions => [ 'requested_at IS NOT NULL' ])
  end
  
  def self.scheduled
    all(:conditions => [ "requested_at IS NULL OR resend = 't'" ])
  end
end

DataMapper.finalize
Response.auto_upgrade!

class MockServer < Sinatra::Base
  use Rack::MethodOverride
  
  configure do
    set :public_folder, 'public'
    set :show_exceptions, settings.development?
  end
  
  helpers Sinatra::Partials

  get '/index' do
    @requests = Response.all(:fields => [:path], :unique => true).map { |r| r.path }
    
    @sent_responses = Response.sent
    @scheduled_responses = Response.scheduled
    
    erb :index    
  end
  
  delete '/response/:id' do |id|
    response = Response.get(id)
    response.destroy if response
    
    redirect '/index'
  end
  
  post '/add' do
    Response.create(:path => params[:path], 
                    :body => params[:body], 
                    :http_status => params[:http_status].to_i,
                    :resend => (params[:resend] == '1'))
    
    redirect '/index'
  end
  
  get '/*' do
    path = params[:splat].first
    parameters = params.delete_if { |k, v| ['splat', 'captures'].include? k }
    
    response = Response.scheduled.first(:path => path)
    if !response
      response = Response.create(:path => path, :body => 'default', :http_status => 200)
    end
    response.attributes = { :requested_at => Time.now }
    response.save

    status response.http_status
    body response.body
  end
end