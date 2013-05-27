require 'rubygems'
require 'bundler/setup'

require 'haml'
require 'sinatra'
require 'mongo'

require_relative './prosedy/draft'
require_relative './prosedy/user'

enable :sessions

$client = Mongo::MongoClient.new('localhost', 27017)
$db = $client.db('storiesarealive')
$users = $db.collection('users')
$drafts = $db.collection('drafts')
DATA_DIR = "./data"

helpers do
    def logged_in?
        if session[:username].nil?
            return false
        else
            return true
        end
    end

    def username
        return session[:username]
    end
end

set(:auth) do |roles| # <- notice the splat here
  condition do
    unless logged_in?
      redirect "/", 303
    end
  end
end

get "/" do
    liquid :index, :locals => { :user => username, :logged_in => logged_in?, :title => "Welcome!" }
end

put "/draft", :auth => :user do
    draft = DraftManager.new(username, params[:title], params[:content])
    draft.create
    redirect '/'
end

get "/draft", :auth => :user do
    drafts = DraftManager.get_drafts(username)
    liquid :draft_list, :locals => { :drafts => drafts }
end

get "/draft/new", :auth => :user do
    liquid :draft, :locals => { :title => "Write a new draft!" }
end

get "/draft/:num", :auth => :user do
    draft = DraftManager.get_draft(username, params[:num].to_i)
    liquid :draft_display, :locals => { :title => draft.draft, :text => draft.content }
end

get "/signup" do
    liquid :signup, :locals => { :title => "Signup!" }
end

post "/signup" do

    username = params[:username]

    if user_m.find_by_name(username)
        redirect "/login"
    end

    # save into mongodb
    user_m.create(username, params[:password])

    session[:username] = username

    # create the directory where we will store git repos for the user
    `mkdir #{DATA_DIR}`
    `mkdir #{DATA_DIR}/#{username}`

    redirect "/"
end

get "/login" do
    liquid :login
end

post "/login" do
    if user = $users.find_one({:name => params[:username]})
        if user["passwordhash"] == BCrypt::Engine.hash_secret(params[:password], user["salt"])
            session[:username] = params[:username]
            redirect "/"
        end
    end
    liquid :login_error
end

get "/logout" do
    session[:username] = nil
    redirect "/"
end
