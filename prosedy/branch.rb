# id, draft, start text, end text, diffs
Branch = Struct.new :_id, :d, :st, :et, :df

class BranchManager
    def initialize(prosedy)
        @prosedy = prosedy
        @branch_db = @prosedy.db.collection('branches')
    end

    def create(branch)
        @branch_db.insert(branch)

        return h_to_st(branch)
    end

    def update(branch_id, content, diffs)
        branch = @branch_db.find_and_modify(query: {_id: branch_id}, update: {'$set' => {et: content, df: diffs}})
        return branch ? h_to_st(branch) : nil
    end

    def get(draft)
        branch = @branch_db.find_one({d: draft._id})
        return branch ? h_to_st(branch) : nil
    end
        
    def h_to_st(h)
        branch = Branch.new
        h.each { |k, v| branch[k] = v }
        return branch
    end
end
