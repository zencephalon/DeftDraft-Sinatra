#                id    user id  numeric id  current draft  draft count
Draft = Struct.new :_id, :uid,    :nid,       :cd,           :dc,         

class DraftManager

    def initialize(prosedy)
        @prosedy = prosedy
        @draft_db = @prosedy.db.collection('drafts')
    end

    def create(uid, title, content)
        nid = @prosedy.user_m.inc_draft_c(uid)
        did = @prosedy.inc_draft_c

        @draft_db.insert(
            {   _id: did, 
                uid: uid, 
                nid: nid, 
                cd: 1,
                dc: 1,
            }
        )

        # create the draft too
        #t: title
    end

    def get(uid, nid)
        draft = @draft_db.find_one({:uid => uid, :nid => nid})
        return nil if draft.nil? 
        ret = Draft.new
        draft.each do |k,v|
            ret[k] = v
        end
        return ret
    end

    def getXuid(id)
        @draft_db.find({:uid => id}).to_a
    end
end
