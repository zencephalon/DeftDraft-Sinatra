require "rubygems"
require "bundler/setup"
require "mongo"

mongo_client = Mongo::MongoClient.new('localhost', 27017)

task :clean do |t|
    mongo_client.drop_database('prosedy')
    `rm -rf ./data`
end

task :setup do |t|
    db = mongo_client.db('prosedy')
    db.collection('prosedy').insert({name: 'data', users: 0, drafts: 0})
    `mkdir ./data`
end

task :start do |t|
    `ruby main.rb`
end
