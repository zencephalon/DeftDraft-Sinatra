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

# ====================== Drafts ===============================================

post "/d", :auth => :user do
    $draft_m.create(user.id, params[:title], params[:deft])
    redirect '/'
end

get "/d", :auth => :user do
    drafts = $draft_m.get_by_uid(user.id)
    liquid :draft_list, :locals => { :drafts => drafts }
end

get "/d/new", :auth => :user do
    liquid :deftdraft, :layout => false, :locals => { title: "", text: "" }
end

get "/d/:num", :auth => :user do
    draft = $draft_m.get(user.id, params[:num].to_i)
    liquid :deftdraft, :layout => false, :locals => { title: draft.title, text: draft.content }
end

get "/d/:num/view", :auth => :user do
    draft = $draft_m.get(user.id, params[:num].to_i)
    liquid :draft_display, :locals => { :title => draft.title, :text => draft.content }
end

get "/w/:num_or_name/d/:d_id" do
    u = $user_m.get_by_id_or_name(params[:num_or_name])
    draft = $draft_m.get(u.id, params[:d_id].to_i)
    liquid :draft_display, :locals => { :title => draft.title, :text => draft.content }
end

# ====================== Users ================================================

get "/w/:num_or_name" do
    u = $user_m.get_by_id_or_name(params[:num_or_name])
    drafts = $draft_m.get_by_uid(u.id)
    puts u.to_s
    puts drafts
    liquid :draft_list, :locals => { :drafts => drafts }
end

get "/signup" do
    liquid :signup, :locals => { :title => "Signup!" }
end

post "/signup" do
    username = params[:username]

    if $user_m.get_by_name(username)
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
