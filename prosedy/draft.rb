# id, writer, numeric id, title
Draft = Struct.new :_id, :w, :n, :t

class DraftManager

    def initialize(prosedy)
        @prosedy = prosedy
        @draft_db = @prosedy.db.collection('drafts')
    end

    def create(w, title, content)
        nid = @prosedy.writer_m.inc_draft_c(w._id)

        #draft_id = BSON::ObjectId.new
        #revision_id = BSON::ObjectId.new

        draft = {   
            w: w._id, 
            n: nid, 
            t: title,
        }

        @draft_db.insert(draft)

        return h_to_st(draft)
    end

    def get(w, n)
        draft = @draft_db.find_one({:w => w, :n => n})
        return draft ? h_to_st(draft) : nil
    end

    def h_to_st(h)
        draft = Draft.new
        h.each { |k, v| draft[k] = v }
        return draft
    end

    def get_by_writer(w)
        @draft_db.find({:w => w}).to_a.map {|h| h_to_st(h)}
    end
end
