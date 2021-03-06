require 'net/http'

require 'partials'
require 'view_helper'

require 'will_paginate'
require 'will_paginate/data_mapper'

# DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, "sqlite3://#{File.dirname(File.expand_path(__FILE__))}/server.db")
DataMapper::Model.raise_on_save_failure = true  # globally across all models

class Response
  include DataMapper::Resource
  property :id, Serial
  property :path, String, :index => :path, :length => 256
  property :http_get, Boolean, :default => true
  property :http_post, Boolean, :default => true
  property :http_put, Boolean, :default => true
  property :http_delete, Boolean, :default => true
  property :http_status, Integer, :default => 200
  property :received_data, String, :length => 4096
  property :match_received_data, Boolean, :default => false
  property :repeat_counter, Integer, :default => 0
  property :paused, Boolean, :default => false
  property :mode, String
  property :forward, String, :length => 256
  property :file, String, :length => 256
  property :tag, String, :length => 64
  property :delay, Float, :default => 0.0
  property :content_type, String
  property :raw_headers, String
  property :body, Text, :length => 500000
  property :requested_at, DateTime

  self.per_page = 30

  before :save do |response|
    Response.normalize_received_data!(response.received_data)
  end

  # http://stackoverflow.com/questions/14217101/what-character-represents-a-new-line-in-a-text-area
  def self.normalize_received_data!(data)
    data.gsub!(/\r\n?/, "\n")
    data.strip!
  end

  def self.sent(options = {})
    all(options.merge({:conditions => [ 'requested_at IS NOT NULL' ], :order => [:requested_at.desc]}))
  end
  
  def self.scheduled(options = {})
    received_data = options[:received_data]
    options.delete :received_data
    
    order = [:paused.asc, :requested_at.asc]
    query = all(options.merge({:conditions => [ "requested_at IS NULL OR repeat_counter <> 0" ], :order => order}))
    if received_data
        normalize_received_data!(received_data)
        query = query & (all(match_received_data: false, :order => order) | all(received_data: received_data, :order => order))
    end
    query
  end
  
  def self.exists_for_path?(path)
    count(:conditions => {:path => path}) > 0
  end
  
  def repeats?
    repeat_counter > 1 || repeat_counter == -1
  end

  def forwards?
    forwards_to_url? || forwards_to_file?
  end
  
  def forwards_to_url?
    mode == "forward_to_url"
  end
  
  def forwards_to_file?
    mode == "forward_to_file"
  end
  
  def has_body?
    body && !body.empty?
  end
  
  def has_received_data?
    received_data && !received_data.empty?
  end

  def headers
    return [] unless raw_headers
    # name1=value1 \n name2=value2 => [[name1, value1], [name2, value2]]
    raw_headers.lines.map { |line| line.partition('=').map(&:chomp).values_at(0, 2) }
  end
  
  def headers=(array)
    if array.nil?
      self.raw_headers = nil
    else
      # [[name1, value1], [name2, value2]] => name1=value1 \n name2=value2
      self.raw_headers = array.collect { |header| header.join('=') }.join("\n")
    end
  end
end

DataMapper.finalize
Response.auto_upgrade!

class MockServer < Sinatra::Base
  use Rack::MethodOverride
  
  configure do
    set :public_folder, 'public'
    set :show_exceptions, settings.development?
    set :haml, :format => :html5
    register Sinatra::Reloader if settings.development?
  end
  
  
  helpers Sinatra::Partials
  helpers ViewHelper
  helpers WillPaginate::Sinatra::Helpers
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end
  
  get '/a-machine/scheduled' do
    @scheduled_responses = Response.scheduled
  
    partial :tab_scheduled, locals: { scheduled: @scheduled_responses }
  end 

  get '/a-machine/sent' do
    @sent_responses = Response.sent.paginate(:page => params[:page])
  
    partial :tab_sent, locals: { sent: @sent_responses }
  end

  get '/a-machine/?' do
    @resp = Response.new
    
    render_index
  end
  
  get '/a-machine/:id/edit' do |id|
    @resp = Response.get(id)
    
    render_index
  end
  
  post '/a-machine' do
    if params[:id].empty? || params[:submit] == "New"
      @resp = Response.new
    else
      @resp = Response.get(params[:id])
    end

    params[:forward].strip!
    params[:file].strip!

    @resp.attributes = {  :path => params[:path],
                          :http_get => params[:http_get] != nil,
                          :http_post => params[:http_post] != nil,
                          :http_put => params[:http_put] != nil,
                          :http_delete => params[:http_delete] != nil,
                          :match_received_data => params[:match_received_data] != nil,
                          :received_data => params[:received_data],
                          :body => params[:body], 
                          :http_status => params[:http_status].to_i,
                          :repeat_counter => params[:repeat_counter],
                          :content_type => params[:content_type],
                          :mode => params[:response_mode],
                          :forward => params[:forward].empty? ? nil : params[:forward],
                          :file => params[:file].empty? ? nil : params[:file],
                          :headers => params[:header_names].nil? ? nil : [params[:header_names], params[:header_values]].transpose,
                          :delay => params[:delay].to_f,
                          :tag => params[:tag]}
    @resp.save
    
    redirect '/a-machine'
  end
  
  put '/a-machine/:id/resend' do |id|
    response = Response.get(id)
    if response
      response.attributes = { :repeat_counter => 1 }
      response.save
    end
    
    redirect '/a-machine'
  end
  
  put '/a-machine/:id/pause' do |id|
    response = Response.get(id)
    if response
      response.attributes = { :paused => 1 }
      response.save
    end
    
    redirect '/a-machine'
  end
  
  put '/a-machine/:id/play' do |id|
    response = Response.get(id)
    if response
      response.attributes = { :paused => 0 }
      response.save
    end
    
    redirect '/a-machine'
  end
  
  delete '/a-machine/:id' do |id|
    response = Response.get(id)
    response.destroy if response
    
    redirect '/a-machine'
  end
  
  get '/*' do
    response_for_current_request
  end
  
  post '/*' do
    response_for_current_request
  end
  
  put '/*' do
    response_for_current_request
  end
  
  delete '/*' do
    response_for_current_request
  end  
  
private

  def render_index
    @requests = Response.all(:fields => [:path], :unique => true, :order => [:path.asc]).map { |r| r.path }

    @sent_responses = Response.sent.paginate(:page => params[:page])
    @scheduled_responses = Response.scheduled
  
    haml :index
  end
  
  def response_for_current_request
    path = params[:splat].first
    parameters = params.delete_if { |k, v| ['splat', 'captures'].include? k }
    path += '?' + Rack::Utils.build_query(parameters) unless parameters.empty?
    received_data = request.env["rack.input"].read


    res = Response.scheduled(path: path, paused: false, "http_" + request.request_method.downcase => true, received_data: received_data).first
    if !res
      res = Response.new(path: path, body: '', http_status: 200, content_type: 'text/html')
    end
    res.attributes = { :requested_at => Time.now }
    res.attributes = { :repeat_counter => res.repeat_counter-1 } if res.repeat_counter > 0

    # delay
    sleep res.delay if res.delay > 0
    
    # content
    status, headers, body = nil
    if res.forwards_to_url?
      status, headers, body = forwarded_response(res)
    elsif res.forwards_to_file?
      status, headers, body = file_response(res)
    else
      headers = { "Content-Type" => res.content_type }
      res.headers.each { |header| headers[header[0]] = header[1] }
      status = res.http_status
      body = res.body
    end
    
    res.body = body if res.forwards?
    
    res.received_data = received_data
    
    begin
      res.save if !res.new? or res.has_received_data? or !Response.exists_for_path? path
    rescue Exception => e
      puts res.errors.inspect
      raise e
    end
    
    [status, (headers if headers), replace_variables(body)]
  end

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
        gsub(/\$\{ruby:(.+?)\}/) { Kernel.eval($1).to_s }
  end

  def forward_headers(request)
    headers = request.env.select { |name, value| name.start_with? 'HTTP_' }
    headers.map! { |name, value| [name.sub(/^HTTP_/, ''), value] }
    Hash[*headers.flatten].delete_if { |name, value| %w(HOST VERSION ORIGIN).include? name }
  end
end
