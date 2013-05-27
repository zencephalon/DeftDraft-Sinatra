require "rubygems"
require 'bcrypt'

User = Struct.new :id, :name

class UserManager
    def initialize(prosedy)
        @prosedy = prosedy
        @mongo_db = @prosedy.db
        @user_db = @mongo_db.collection('users')
        @prosedy_db = @mongo_db.collection('prosedy')
    end

    def create(name, password)
        user_id = @prosedy_db.find_and_modify(:query => {:name => "data"}, :update => {"$inc" => {"users" => 1}}, :new => true)['users']

        password_salt = BCrypt::Engine.generate_salt
        password_hash = BCrypt::Engine.hash_secret(password, password_salt)

        @user_db.insert({name: name, _id: user_id, pw_hash: password_hash, pw_salt: password_salt})

        `mkdir #{@prosedy.data_dir}/#{user_id}`
    end

    def find_by_name(name)
        result = @user_db.find_one({name: name})
        if result
            User.new(result['id'], result['name']);
        end
    end
end
