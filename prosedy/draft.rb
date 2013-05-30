
#                  id    user id  numeric id  current revision  revision count  title
Draft = Struct.new :_id, :w,    :n,         :cr,              :rc,            :t

class DraftManager

    def initialize(prosedy)
        @prosedy = prosedy
        @draft_db = @prosedy.db.collection('drafts')
    end

    def create(wid, title, content)
        nid = @prosedy.writer_m.inc_draft_c(uid)

        draft_id = BSON::ObjectId.new
        revision_id = BSON::ObjectId.new

        draft = {   
            _id: draft_id,
            w: wid, 
            n: nid, 
            t: title,
            cr: revision_id,
            rc: 1,
        }

        @draft_db.insert(draft)

        return h_to_st(draft)
    end

    def get(w, n)
        draft = @draft_db.find_one({:w => w, :n => n})
        draft ? 
        return nil if draft.nil? 
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
