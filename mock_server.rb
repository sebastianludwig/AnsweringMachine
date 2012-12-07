require 'partials'

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, "sqlite3://#{File.dirname(File.expand_path(__FILE__))}/server.db")
DataMapper::Model.raise_on_save_failure = true  # globally across all models

class Response
  include DataMapper::Resource
  property :id, Serial
  property :path, String, :index => :path
  property :http_status, Integer, :default => 200
  property :resend_counter, Integer, :default => 0
  #property :forward, String
  property :content_type, String
  property :body, String
  property :requested_at, DateTime
  
  default_scope(:default).update(:order => [:requested_at.desc])
  
  def self.sent
    all(:conditions => [ 'requested_at IS NOT NULL' ])
  end
  
  def self.scheduled
    all(:conditions => [ "requested_at IS NULL OR resend_counter <> 0" ])
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
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end

  get '/index' do
    @requests = Response.all(:fields => [:path], :unique => true).map { |r| r.path }
    
    @sent_responses = Response.sent
    @scheduled_responses = Response.scheduled
    
    erb :index    
  end
  
  post '/add' do
    Response.create(:path => params[:path], 
                    :body => params[:body], 
                    :http_status => params[:http_status].to_i,
                    :resend_counter => params[:resend_counter],
                    :content_type => params[:content_type])
    
    redirect '/index'
  end
  
  put '/resend/:id' do |id|
    response = Response.get(id)
    response.attributes = { :resend_counter => 1 } if response
    response.save
    
    redirect '/index'
  end
  
  delete '/response/:id' do |id|
    response = Response.get(id)
    response.destroy if response
    
    redirect '/index'
  end
  
  
  get '/*' do
    path = params[:splat].first
    parameters = params.delete_if { |k, v| ['splat', 'captures'].include? k }
    
    response = Response.scheduled.last(:path => path)
    if !response
      response = Response.create(:path => path, :body => '', :http_status => 200, :content_type => 'text/html')
    end
    response.attributes = { :requested_at => Time.now }
    response.attributes = { :resend_counter => response.resend_counter-1 } if response.resend_counter > 0
    response.save
    
    content_type response.content_type
    status response.http_status
    body response.body
  end
end