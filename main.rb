require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'mongo'
require 'redcloth'
require 'puma'

require_relative './prosedy/prosedy'

class Prose < Sinatra::Base
    enable :sessions
    set :bind, '0.0.0.0'

    $prosedy = Prosedy.new(Mongo::MongoClient.new('localhost', 27017))
    $writer_m = $prosedy.writer_m
    $draft_m = $prosedy.draft_m
    $branch_m = $prosedy.branch_m

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
            if params[:branch].empty?
                $draft_m.create(writer, params[:title], params[:deft], params[:diffs])
            else
                $draft_m.update(writer, params[:title], params[:deft], params[:diffs], params[:branch])
            end
            redirect '/'
        end

        get "#{path}", :auth => :writer do
            drafts = $draft_m.get_by_writer(writer._id)
            liquid :draft_list, :locals => { :drafts => drafts }
        end

        get "#{path}/new", :auth => :writer do
            liquid :deftdraft, :layout => false, :locals => { title: "", text: "" }
        end

        get "#{path}/:num/edit", :auth => :writer do
            draft = $draft_m.get(writer._id, params[:num])
            branch = $branch_m.get(draft)
            # load the drafts for this draft
            liquid :deftdraft, :layout => false, :locals => { title: draft.t, text: branch.et, diffs: branch.df, branch: branch._id.to_s }
        end

        get "#{path}/:num/view", :auth => :writer do
            draft = $draft_m.get(writer._id, params[:num])
            branch = $branch_m.get(draft)
            # load the current draft for this draft
            liquid :draft_display, :layout => false, :locals => { :title => draft.t, :text => RedCloth.new(branch.et).to_html, :starting_text => branch.st, :diffs => branch.df }
        end
    end

    get "/w/:name/d/:num" do
        writer = $writer_m.find_by_name(params[:name])
        draft = $draft_m.get(writer._id, params[:num])
        branch = $branch_m.get(draft)
        # load the current draft for this draft
        liquid :draft_display, :layout => false, :locals => { :title => draft.t, :text => RedCloth.new(branch.et).to_html, :starting_text => branch.st, :diffs => branch.df }
    end

    # ====================== Users ================================================

    get "/w/:name" do
        w = $writer_m.find_by_name(params[:name])
        drafts = $draft_m.get_by_writer(w._id)
        liquid :public_draft_list, :locals => { drafts: drafts, writer: w.n }
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
end

if __FILE__ == $0
    Prose.run!
end
