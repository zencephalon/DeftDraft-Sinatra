require 'rubygems'
require 'bundler/setup'

require 'bcrypt'
require 'haml'
require 'sinatra'
require 'mongo'

enable :sessions

$client = Mongo::MongoClient.new('localhost', 27017)
$db = $client.db('storiesarealive')
$users = $db.collection('users')
$drafts = $db.collection('drafts')
DATA_DIR = "./data"

class Draft
    attr_accessor :content, :draft

    def initialize(user, draft, content)
        @user, @draft, @content = user, draft, content
        @dir = "#{DATA_DIR}/#{@user}/#{@draft}"
    end

    def create
        if $drafts.find_one({:user => @user, :draft => @draft})
            raise 'Draft already exists'
        end

        `mkdir #{@dir}`
        `git init #{@dir}`

        draft_id = $users.find_and_modify(:query => {:user => @user}, :update => {"$inc" => {"draft_count" => 1}}, :new => true)['draft_count']
        $drafts.insert({:user => @user, :draft => @draft, :dir => @dir, :num => draft_id})

        File.open("#{@dir}/draft.textile", 'w') do |f|
            f.puts @content
        end

        `git --git-dir=#{@dir}/.git --work-tree=#{@dir} add draft.textile`
        `git --git-dir=#{@dir}/.git --work-tree=#{@dir} commit -a -m 'initial commit'`
    end

    def self.get_draft(user, num)
        draft = $drafts.find_one({:user => user, :num => num})
        return nil if draft.nil? 
        draft['content'] = File.open("#{draft['dir']}/draft.textile").read
        return Draft.new(user, draft['draft'], draft['content'])
    end

    def self.get_drafts(user)
        $drafts.find({:user => user}).to_a
    end
end

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
    draft = Draft.new(username, params[:title], params[:content])
    draft.create
    redirect '/'
end

get "/draft", :auth => :user do
    drafts = Draft.get_drafts(username)
    liquid :draft_list, :locals => { :drafts => drafts }
end

get "/draft/new", :auth => :user do
    liquid :draft, :locals => { :title => "Write a new draft!" }
end

get "/draft/:num", :auth => :user do
    draft = Draft.get_draft(username, params[:num].to_i)
    liquid :draft_display, :locals => { :title => draft.draft, :text => draft.content }
end

get "/signup" do
    liquid :signup, :locals => { :title => "Signup!" }
end

post "/signup" do
    password_salt = BCrypt::Engine.generate_salt
    password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

    username = params[:username].gsub /[^a-z0-9\-]+/i, '_'

    if $users.find_one({:user => params[:username]})
        redirect "/login"
    end

    # save into mongodb
    $users.insert({
        :user => username,
        :salt => password_salt,
        :passwordhash => password_hash 
    })

    session[:username] = username

    # create the directory where we will store git repos for the user
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
