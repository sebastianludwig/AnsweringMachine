require 'net/http'

require 'partials'
require 'view_helper'

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, "sqlite3://#{File.dirname(File.expand_path(__FILE__))}/server.db")
DataMapper::Model.raise_on_save_failure = true  # globally across all models

class Response
  include DataMapper::Resource
  property :id, Serial
  property :path, String, :index => :path, :length => 256
  property :http_status, Integer, :default => 200
  property :resend_counter, Integer, :default => 0
  property :forward, String, :length => 256
  property :delay, Float, :default => 0
  property :content_type, String
  property :body, Text
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
  helpers ViewHelper
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end

  get '/index' do
    @requests = Response.all(:fields => [:path], :unique => true).map { |r| r.path }
    
    @sent_responses = Response.sent
    @scheduled_responses = Response.scheduled
    
    haml :index, :format => :html5
  end
  
  post '/add' do
    params[:forward].strip!
    Response.create(:path => params[:path], 
                    :body => params[:body], 
                    :http_status => params[:http_status].to_i,
                    :resend_counter => params[:resend_counter],
                    :content_type => params[:content_type],
                    :forward => params[:forward].empty? ? nil : params[:forward],
                    :delay => params[:delay].to_f)
    
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
    
    res = Response.scheduled.last(:path => path)
    if !res
      res = Response.create(:path => path, :body => '', :http_status => 200, :content_type => 'text/html')
    end
    res.attributes = { :requested_at => Time.now }
    res.attributes = { :resend_counter => res.resend_counter-1 } if res.resend_counter > 0
    res.save
    
    sleep res.delay if res.delay > 0
    
    if res.forward
      uri = URI(res.forward)
      req = Net::HTTP::Get.new(uri.request_uri)
      
      forward_headers(request).each { |name, value| req[name] = value }

      result = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
      
      header = {}
      result.each_header do |name, value|
        header[name] = value unless %w(transfer-encoding).include? name
      end
      
      status result.code.to_i
      headers header
      body(result.body) if result.class.body_permitted?
      return
    end
    
    content_type res.content_type
    status res.http_status
    body res.body
  end
  
private

  def forward_headers(request)
    headers = request.env.select { |name, value| name.start_with? 'HTTP_' }
    headers.map! { |name, value| [name.sub(/^HTTP_/, ''), value] }
    Hash[*headers.flatten].delete_if { |name, value| %w(HOST VERSION ORIGIN).include? name }
  end
end