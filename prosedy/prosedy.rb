require 'rubygems'
require 'pathname'
require 'mongo'
require_relative "user"
require_relative "draft"

class Prosedy
    attr_reader :db, :data_dir, :user_m, :draft_m

    def initialize(client)
        @client = client
        @db = @client.db('prosedy')
        @data_dir = Pathname.new('../data').expand_path.to_s
        @user_m = UserManager.new(self)
        @draft_m = DraftManager.new(self)
    end

    def increment_user_count
        @db.collection('prosedy').find_and_modify(:query => {:name => "data"}, :update => {"$inc" => {"users" => 1}}, :new => true)['users']
    end

    def increment_draft_count
        @db.collection('prosedy').find_and_modify(:query => {:name => "data"}, :update => {"$inc" => {"drafts" => 1}}, :new => true)['drafts']
    end
end
