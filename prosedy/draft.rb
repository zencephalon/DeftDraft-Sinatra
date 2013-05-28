Draft = Struct.new :id, :uid, :title, :content

class DraftManager
    DRAFT_FILE_NAME = "draft"

    def initialize(prosedy)
        @prosedy = prosedy
        @draft_db = @prosedy.db.collection('drafts')
    end

    def create(uid, title, content)
       # if draft_db.find_one({uid: uid, title: title})
       #     raise 'Draft already exists'
       # end
        num = @prosedy.user_m.increment_draft_count(uid)
        did = @prosedy.increment_draft_count

        dir = "#{@prosedy.data_dir}/#{uid}/#{num}"
        `mkdir #{dir}`
        `git init #{dir}`

        @draft_db.insert({uid: uid, title: title, num: num, _id: did})

        File.open("#{dir}/#{DRAFT_FILE_NAME}", 'w') do |f|
            f.puts content
        end

        `git --git-dir=#{@dir}/.git --work-tree=#{@dir} add #{DRAFT_FILE_NAME}`
        `git --git-dir=#{@dir}/.git --work-tree=#{@dir} commit -a -m 'initial commit'`
    end

    def get(uid, num)
        draft = @draft_db.find_one({:uid => user, :num => num})
        return nil if draft.nil? 
        draft['content'] = File.open("#{draft['dir']}/#{DRAFT_FILE_NAME}").read
        return Draft.new(draft['_id'], draft['uid'], draft['title'], draft['content'])
    end

    def get_by_uid(id)
        @draft_db.find({:uid => id}).to_a
    end
end
