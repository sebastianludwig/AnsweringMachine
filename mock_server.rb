
#DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, "sqlite3://#{File.dirname(File.expand_path(__FILE__))}/twplus.db")
DataMapper::Model.raise_on_save_failure = true  # globally across all models

class Request
  include DataMapper::Resource
  property :id, Serial
  property :path, String, :index => :path
end

DataMapper.finalize
Request.auto_upgrade!

class MockServer < Sinatra::Base
  configure do
    set :public, 'public'
    set :show_exceptions, settings.development?
  end

  get '/index' do
    @requests = Request.all
    
    erb :index    
  end
  
  get '/*' do
    path = params[:splat].first
    request_parameters = params.delete_if { |k, v| ['splat', 'captures'].include? k }
    
    request = Request.create(:path => path)
  end
end