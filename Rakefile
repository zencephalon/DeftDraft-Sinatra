require "rubygems"
require "bundler/setup"
require "mongo"
require_relative './prosedy/prosedy'

mongo_client = Mongo::MongoClient.new('localhost', 27017)
prosedy = Prosedy.new(Mongo::MongoClient.new('localhost', 27017))
writer_m = $prosedy.writer_m
draft_m = $prosedy.draft_m

task :clean do |t|
    mongo_client.drop_database('prosedy')
end

task :setup do |t|
    db = mongo_client.db('prosedy')
    db.collection('prosedy').insert({name: 'data', users: 0, drafts: 0})
    writer_m.create(zen, zen)
end

task :start do |t|
    `ruby main.rb`
end
