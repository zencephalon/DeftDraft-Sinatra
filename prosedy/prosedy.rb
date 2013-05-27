require 'rubygems'
require 'pathname'
require 'mongo'

class Prosedy
    attr_reader :db, :data_dir

    def initialize
        @client = Mongo::MongoClient.new('localhost', 27017)
        @db = @client.db('prosedy')
        @data_dir = Pathname.new('../data').expand_path.to_s
    end

    def increment_user_count
        @db.collection('prosedy').find_and_modify(:query => {:name => "data"}, :update => {"$inc" => {"users" => 1}}, :new => true)['users']
    end
end
