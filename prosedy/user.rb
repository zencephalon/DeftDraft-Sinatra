require "rubygems"
require 'bcrypt'

User = Struct.new :id, :name, :pw_hash, :pw_salt

class UserManager
    def initialize(prosedy)
        @prosedy = prosedy
        @user_db = @prosedy.db.collection('users')
    end

    def create(name, password)
        uid = @prosedy.increment_user_count

        password_salt = BCrypt::Engine.generate_salt
        password_hash = BCrypt::Engine.hash_secret(password, password_salt)

        @user_db.insert({name: name, _id: uid, pw_hash: password_hash, pw_salt: password_salt, drafts: 0})

        `mkdir #{@prosedy.data_dir}/#{uid}`

        return User.new(uid, name)
    end

    def login(name, password)
        user = find_by_name(name)
        (user && user.pw_hash == BCrypt::Engine.hash_secret(password, user.pw_salt)) ? user : nil
    end

    def increment_draft_count(id)
        @user_db.find_and_modify(query: {_id: id}, update: {'$inc' => {drafts: 1}}, new: true)['drafts']
    end

    def get_by_name(name)
        if result = @user_db.find_one({name: name})
            return User.new(result['_id'], result['name'], result['pw_hash'], result['pw_salt']);
        else 
            return nil
        end
    end

    def get_by_id(id)
        if result = @user_db.find_one({_id: id})
            return User.new(result['_id'], result['name'], result['pw_hash'], result['pw_salt']);
        else 
            return nil
        end
    end

    def get_by_id_or_name(name_or_id)
        if result = get_by_id(name_or_id.to_i)
            return result
        elsif result = get_by_name(name_or_id)
            return result
        else
            return nil
        end
    end
end
