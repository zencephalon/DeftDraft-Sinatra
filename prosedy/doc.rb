#                id    user id  numeric id  current draft  draft count  title
Doc = Struct.new :_id, :uid,    :nid,       :cd,           :dc,         :t

class DocManager

    def initialize(prosedy)
        @prosedy = prosedy
        @doc_db = @prosedy.db.collection('documents')
    end

    def create(uid, title, content)
        nid = @prosedy.user_m.inc_doc_c(uid)
        did = @prosedy.inc_doc_c

        @doc_db.insert(
            {   _id: did, 
                uid: uid, 
                nid: nid, 
                cd: 1,
                dc: 1,
                t: title
            }
        )

        # create the draft too
    end

    def get(uid, nid)
        doc = @doc_db.find_one({:uid => uid, :nid => nid})
        return nil if draft.nil? 
        ret = Doc.new
        doc.each do |k,v|
            ret[k] = v
        end
        return ret
    end

    def getXuid(id)
        @doc_db.find({:uid => id}).to_a
    end
end
