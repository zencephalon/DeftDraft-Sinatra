require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'mongo'

require_relative './prosedy/prosedy'

enable :sessions
set :bind, '0.0.0.0'

$prosedy = Prosedy.new(Mongo::MongoClient.new('localhost', 27017))
$writer_m = $prosedy.writer_m
$draft_m = $prosedy.draft_m

helpers do
    def logged_in?
        if session[:writer].nil?
            return false
        else
            return true
        end
    end

    def writer
        return session[:writer]
    end
end

set(:auth) do |roles|
  condition do
    unless logged_in?
      redirect "/", 303
    end
  end
end

# =============================================================================

get "/" do
    liquid :index, :locals => { :writer => writer ? writer.n : nil, :logged_in => logged_in?, :title => "Welcome!" }
end

# ====================== Drafts ===============================================

["/draft", "/d"].each do |path|
    post "#{path}", :auth => :writer do
        $draft_m.create(writer._id, params[:title], params[:deft])
        redirect '/'
    end

    get "#{path}", :auth => :writer do
        drafts = $draft_m.get_by_writer(writer._id)
        liquid :draft_list, :locals => { :drafts => drafts }
    end

    get "#{path}/new", :auth => :writer do
        liquid :deftdraft, :layout => false, :locals => { title: "", text: "" }
    end

    get "#{path}/:num", :auth => :writer do
        draft = $draft_m.get(writer._id, params[:num].to_i)
        # load the drafts for this draft
        #liquid :deftdraft, :layout => false, :locals => { title: draft.title, text: draft.content }
    end

    get "#{path}/:num/view", :auth => :writer do
        draft = $draft_m.get(writer._id, params[:num].to_i)
        # load the current draft for this draft
        liquid :draft_display, :locals => { :title => draft.title, :text => draft.content }
    end
end

get "/w/:num_or_name/d/:d_id" do
    w = $writer_m.get_by_id_or_name(params[:num_or_name])
    draft = $draft_m.get(w._id, params[:d_id].to_i)
    # load the current draft for this draft
    liquid :draft_display, :locals => { :title => draft.title, :text => draft.content }
end

# ====================== Users ================================================

get "/w/:num_or_name" do
    w = $writer_m.find_by_name(params[:num_or_name])
    drafts = $draft_m.get_by_writer(w._id)
    liquid :draft_list, :locals => { :drafts => drafts }
end

get "/signup" do
    liquid :signup, :locals => { :title => "Signup!" }
end

post "/signup" do
    username = params[:username]

    if $writer_m.find_by_name(username)
        redirect "/login"
    end

    # save into mongodb
    session[:writer] = $writer_m.create(username, params[:password])

    redirect "/"
end

get "/login" do
    liquid :login
end

post "/login" do
    if writer = $writer_m.login(params[:username], params[:password])
        session[:writer] = writer
        redirect "/"
    else
        liquid :login_error
    end
end

get "/logout" do
    session[:writer] = nil
    redirect "/"
end
