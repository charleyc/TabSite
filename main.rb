# main.rb, requires Ruby 1.9
# rather than get a new directory listing every time a search is done,
# would be interesting to try to use threads to update a static directory listing
# once every 30 seconds, for example

require 'sinatra/base'
require 'haml'

DB_FILE = './database.rb'
require DB_FILE

MAX_SIZE_KB = 1000 

class FileTooLargeError < StandardError; end

class MyApp < Sinatra::Base  
  enable :sessions, :static
  set :root, File.dirname(__FILE__)
  set :tabdir, File.join(root, "tabs")

  def initialize
    super
    @login_manager = LoginManager.new
  end
  
  helpers do
    def search_tabs(key)
      # returns an array of filenames matching the search criterion; is very stupid
      # also, does not check that @key is of reasonable length
      result_exp = File.join(settings.tabdir, "*#{key}*.txt") 
      results = Dir.glob(result_exp)
      results.map {|x| File.basename(x)}
    end

    def validate(username, password)
      # stupid login logic, also, should return user id on success
      return @login_manager.validate(username,password)
    end

    def get_tab(filename)
      File.join(settings.tabdir, "#{filename}.txt")
    end

    def logged_in?
      return session[:logged_in] == true
    end

    def submit_tab(title, artist, tabfile, submitter)
      #logic should be changed to store searchable metadata in a database
      # better design: this manages all the logic involving field requirements, etc,
      # primarily by passing on to the database manager
      # if something goes wrong, the manager passes back data used in the view to regenerate as
      # much of the form data as possible, highlight bad fields, etc, then here we organize that
      # data and raise the desired exception.

      raise FileTooLargeError
    end
  end

  get '/' do
    haml :index
  end

  get '/tabs/*.txt' do |filename|
    tab = get_tab(filename)
    send_file tab
  end

  get '/search' do
    haml :search
  end

  get '/login' do
    haml :login
  end

  get '/logout' do
    session.clear
    @message = "Logged out successfully."
    haml :index
  end
  
  get '/submit' do
    if !logged_in?
      "You must be logged in to submit tabs."
    else
      haml :submit
    end
  end

  post '/login' do
    if uid = validate(params["username"], params["password"])
      puts "User logged in: username = #{params[:username]}, uid = #{uid}"
      session["logged_in"] = true
      session["username"] = params["username"]
      session["uid"] = uid
      @message = "Logged in successfully!  Welcome back, #{session[:username]}!"
      haml :index
    else
      puts "Failed login: #{params[:username]}"
      @error_message = "Username or password incorrect."
      haml :login
    end
  end

  post '/search' do
    @query = params["query"]
    @results = search_tabs(@query)
    haml :search_results
  end

  post '/submit' do
    if !logged_in?
      @error = "You must be logged in to submit tablature!"
      haml :login
    else
      title = params[:title].strip
      artist = params[:artist].strip
      if title == ""# this needs to carefully check for allowable characters, correct length, etc; should be a helper function
        # later this should be changed to retain correct fields and highlight incorrect fields
        @error_message = "The title field is required!"
        haml :submit
      elsif artist == ""
        @error_message = "The artist field is required!"
        haml :submit
      else
        tabfile = params[:tab_file][:tempfile]
        submitter = session[:username]
        begin
          submit_tab(title,artist,tabfile,submitter) #not yet written
          @message = "Tab successfully submitted!"
          haml :index
        rescue FileTooLargeError
          @error_message = "Error: file too large.  Max file size is #{MAX_SIZE_KB} KB"
          haml :submit
        end
      end
    end  
  end

  not_found do
    "404 Not Found"
  end
end
