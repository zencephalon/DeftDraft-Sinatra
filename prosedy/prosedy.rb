require 'pathname'

class Prosedy
    attr_reader :db, :data_dir

    def initialize
        @db = Mongo::MongoClient.new('localhost', 27017)
        @data_dir = Pathname.new('../data').expand_path.to_s
    end
end
