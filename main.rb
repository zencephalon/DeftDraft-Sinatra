require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'mongo'

require_relative './prosedy/prosedy'

enable :sessions

$prosedy = Prosedy.new(Mongo::MongoClient.new('localhost', 27017))
$user_m = $prosedy.user_m
$draft_m = $prosedy.draft_m

helpers do
    def logged_in?
        if session[:user].nil?
            return false
        else
            return true
        end
    end

    def user
        return session[:user]
    end
end

set(:auth) do |roles|
  condition do
    unless logged_in?
      redirect "/", 303
    end
  end
end

get "/" do
    liquid :index, :locals => { :user => user ? user.name : nil, :logged_in => logged_in?, :title => "Welcome!" }
end

put "/draft", :auth => :user do
    #draft = DraftManager.new(username, params[:title], params[:content])
    #draft.create
    $draft_m.create(user.id, params[:title], params[:content])
    redirect '/'
end

get "/draft", :auth => :user do
    drafts = $draft_m.get_by_uid(user.id)
    liquid :draft_list, :locals => { :drafts => drafts }
end

get "/draft/new", :auth => :user do
    liquid :deftdraft, :layout => false, :locals => { :title => "Write a new draft!" }
end

get "/draft/:num", :auth => :user do
    draft = $draft_m.get(user.id, params[:num].to_i)
    liquid :draft_display, :locals => { :title => draft.title, :text => draft.content }
end

get "/signup" do
    liquid :signup, :locals => { :title => "Signup!" }
end

post "/signup" do
    username = params[:username]

    if $user_m.find_by_name(username)
        redirect "/login"
    end

    # save into mongodb
    session[:user] = $user_m.create(username, params[:password])

    redirect "/"
end

get "/login" do
    liquid :login
end

post "/login" do
    if user = $user_m.login(params[:username], params[:password])
        session[:user] = user
        redirect "/"
    else
        liquid :login_error
    end
end

get "/logout" do
    session[:user] = nil
    redirect "/"
end
