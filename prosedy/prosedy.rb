require 'rubygems'
require 'pathname'
require 'mongo'
require_relative "writer"
require_relative "draft"
require_relative "revision"
require_relative "branch"

class Prosedy
    attr_reader :db, :data_dir, :writer_m, :draft_m, :branch_m

    def initialize(client)
        @client = client
        @db = @client.db('prosedy')
        @data_dir = Pathname.new('../data').expand_path.to_s
        @writer_m = WriterManager.new(self)
        @draft_m = DraftManager.new(self)
        @branch_m = BranchManager.new(self)
    end

    def increment_user_count
        @db.collection('prosedy').find_and_modify(:query => {:name => "data"}, :update => {"$inc" => {"users" => 1}}, :new => true)['users']
    end

    def increment_draft_count
        @db.collection('prosedy').find_and_modify(:query => {:name => "data"}, :update => {"$inc" => {"drafts" => 1}}, :new => true)['drafts']
    end
end
