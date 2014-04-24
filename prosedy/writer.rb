require 'rubygems'
require 'bcrypt'

Writer = Struct.new :_id, :n, :dc, :ph, :ps

class WriterManager
    def initialize(prosedy)
        @prosedy = prosedy
        @writer_db = @prosedy.db.collection('writers')
    end

    def h_to_st(writer)
        w = Writer.new
        writer.each { |k,v| w[k] = v }
        return w
    end

    def create(name, password)
        return nil if @writer_db.find_one({n: name})

        ps = BCrypt::Engine.generate_salt
        ph = BCrypt::Engine.hash_secret(password, ps)

        writer = {n: name, ph: ph, ps: ps, dc: 0}
        @writer_db.insert(writer)

        return sanitize(h_to_st(writer))
    end

    def sanitize(writer)
        writer.ph = nil
        writer.ps = nil
        writer
    end

    def login(name, password)
        writer = find_by_name(name)
        (writer && writer.ph == BCrypt::Engine.hash_secret(password, writer.ps)) ? sanitize(writer) : nil
    end

    def inc_draft_c(id)
        @writer_db.find_and_modify(query: {_id: id}, update: {'$inc' => {dc: 1}}, fields: {dc: true}, new: true)['dc']
    end

    def find_by_name(name)
        writer = @writer_db.find_one({n: name})
        return writer ? h_to_st(writer) : nil
    end
end


