# id, writer, numeric id, title
Draft = Struct.new :_id, :w, :n, :t, :b, :mk

class DraftManager
    def initialize(prosedy)
        @prosedy = prosedy
        @draft_db = @prosedy.db.collection('drafts')
    end

    def create(w, title, content, diffs)
        nid = @prosedy.writer_m.inc_draft_c(w._id)

        draft_id = BSON::ObjectId.new
        branch_id = BSON::ObjectId.new
        #revision_id = BSON::ObjectId.new

        branch = {
            _id: branch_id,
            st: "",
            et: content,
            df: diffs,
            d: draft_id
        }

        @prosedy.branch_m.create(branch)

        draft = {   
            _id: draft_id,
            w: w._id, 
            n: nid, 
            t: title,
            b: branch_id,
            mk: "textile"
        }

        @draft_db.insert(draft)

        return h_to_st(draft)
    end

    def update(w, title, content, diffs, branch_id_s)
        branch = @prosedy.branch_m.update(BSON::ObjectId.from_string(branch_id_s), content, diffs)
        @draft_db.update({_id: branch.d}, {'$set' => {t: title}})
    end

    def get(w, n)
        draft = @draft_db.find_one({:w => w, :n => n.to_i})
        return draft ? h_to_st(draft) : nil
    end

    def h_to_st(h)
        draft = Draft.new
        h.each { |k, v| draft[k] = v }
        return draft
    end

    def get_by_writer(w)
        @draft_db.find({:w => w}).to_a
    end
end
