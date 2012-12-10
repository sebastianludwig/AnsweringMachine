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
  property :repeat_counter, Integer, :default => 0
  property :paused, Boolean, :default => 0
  property :forward, String, :length => 256
  property :file, String, :length => 256
  property :tag, String, :length => 64
  property :delay, Float, :default => 0
  property :content_type, String
  property :body, Text, :length => 500000
  property :requested_at, DateTime
  
  def self.sent(options = {})
    all(options.merge({:conditions => [ 'requested_at IS NOT NULL' ], :order => [:requested_at.desc]}))
  end
  
  def self.scheduled(options = {})
    all(options.merge({:conditions => [ "requested_at IS NULL OR repeat_counter <> 0" ], :order => [:requested_at.asc]}))
  end
  
  def repeats?
    repeat_counter > 1 || repeat_counter == -1
  end

  def forwards?
    forwards_to_url? || forwards_to_file?
  end
  
  def forwards_to_url?
    forward && !forward.empty?
  end
  
  def forwards_to_file?
    file && !file.empty?
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

  get '/a-machine' do
    @requests = Response.all(:fields => [:path], :unique => true).map { |r| r.path }
    
    @sent_responses = Response.sent
    @scheduled_responses = Response.scheduled
    
    haml :index, :format => :html5
  end
  
  post '/a-machine/add' do
    params[:forward].strip!
    params[:file].strip!
    Response.create(:path => params[:path], 
                    :body => params[:body], 
                    :http_status => params[:http_status].to_i,
                    :repeat_counter => params[:repeat_counter],
                    :content_type => params[:content_type],
                    :forward => params[:forward].empty? ? nil : params[:forward],
                    :file => params[:file].empty? ? nil : params[:file],
                    :delay => params[:delay].to_f,
                    :tag => params[:tag])
    
    redirect '/a-machine'
  end
  
  put '/a-machine/resend/:id' do |id|
    response = Response.get(id)
    if response
      response.attributes = { :repeat_counter => 1 }
      response.save
    end
    
    redirect '/a-machine'
  end
  
  put '/a-machine/pause/:id' do |id|
    response = Response.get(id)
    if response
      response.attributes = { :paused => 1 }
      response.save
    end
    
    redirect '/a-machine'
  end
  
  put '/a-machine/play/:id' do |id|
    response = Response.get(id)
    if response
      response.attributes = { :paused => 0 }
      response.save
    end
    
    redirect '/a-machine'
  end
  
  delete '/a-machine/response/:id' do |id|
    response = Response.get(id)
    response.destroy if response
    
    redirect '/a-machine'
  end
  
  get '/*' do
    path = params[:splat].first
    parameters = params.delete_if { |k, v| ['splat', 'captures'].include? k }
    
    res = Response.scheduled(:path => path, :paused => false).first
    if !res
      res = Response.create(:path => path, :body => '', :http_status => 200, :content_type => 'text/html')
    end
    res.attributes = { :requested_at => Time.now }
    res.attributes = { :repeat_counter => res.repeat_counter-1 } if res.repeat_counter > 0
    res.save
    
    sleep res.delay if res.delay > 0
    
    status, headers, body = nil
    if res.forwards_to_url?
      status, headers, body = forwarded_response(res)
    elsif res.forwards_to_file?
      status, headers, body = file_response(res)
    else
      headers = { "Content-Type" => res.content_type }
      status = res.http_status
      body = res.body
    end
    
    status(status)
    headers(headers) if headers
    body(replace_variables(body))
  end
  
private

  def forwarded_response(response)
    uri = URI(response.forward)
    req = Net::HTTP::Get.new(uri.request_uri)
    
    forward_headers(request).each { |name, value| req[name] = value }

    result = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
    
    headers = {}
    result.each_header do |name, value|
      headers[name] = value unless %w(transfer-encoding).include? name
    end
    
    [result.code.to_i, headers, (result.body if result.class.body_permitted?)]
  end
  
  def file_response(response)
    content_type = IO.popen("file --brief --mime-type #{response.file}").read.chomp
    [200, { "Content-Type" => content_type }, File.open(response.file, "r").read]
  end

  def replace_variables(body)
    body.gsub(/\$\{timestamp\}/, Time.now.to_i.to_s).
        gsub(/\$\{eval:(.+)\}/) { Kernel.eval($1).to_s }
  end

  def forward_headers(request)
    headers = request.env.select { |name, value| name.start_with? 'HTTP_' }
    headers.map! { |name, value| [name.sub(/^HTTP_/, ''), value] }
    Hash[*headers.flatten].delete_if { |name, value| %w(HOST VERSION ORIGIN).include? name }
  end
end