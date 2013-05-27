require "rubygems"
require 'bcrypt'

User = Struct.new :id, :name, :pw_hash, :pw_salt

class UserManager
    def initialize(prosedy)
        @prosedy = prosedy
        @user_db = @prosedy.db.collection('users')
    end

    def create(name, password)
        user_id = @prosedy.increment_user_count

        password_salt = BCrypt::Engine.generate_salt
        password_hash = BCrypt::Engine.hash_secret(password, password_salt)

        @user_db.insert({name: name, _id: user_id, pw_hash: password_hash, pw_salt: password_salt})

        `mkdir #{@prosedy.data_dir}/#{user_id}`
    end

    def login(name, password)
        user = find_by_name(name)
        return (user && user.pw_hash == BCrypt::Engine.hash_secret(password, user.pw_salt))
    end

    def find_by_name(name)
        if result = @user_db.find_one({name: name})
            return User.new(result['id'], result['name'], result['pw_hash'], result['pw_salt']);
        else 
            return nil
        end
    end
end
