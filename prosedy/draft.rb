Draft = Struct.new :id, :user_id, :title, :content

class DraftManager
    attr_accessor :content, :draft

    def initialize(user, draft, content)
        @user, @draft, @content = user, draft, content
        @dir = "#{DATA_DIR}/#{@user}/#{@draft}"
    end

    def create
        if $drafts.find_one({:user => @user, :draft => @draft})
            raise 'Draft already exists'
        end

        `mkdir #{@dir}`
        `git init #{@dir}`

        draft_id = $users.find_and_modify(:query => {:user => @user}, :update => {"$inc" => {"draft_count" => 1}}, :new => true)['draft_count']
        $drafts.insert({:user => @user, :draft => @draft, :dir => @dir, :num => draft_id})

        File.open("#{@dir}/draft.textile", 'w') do |f|
            f.puts @content
        end

        `git --git-dir=#{@dir}/.git --work-tree=#{@dir} add draft.textile`
        `git --git-dir=#{@dir}/.git --work-tree=#{@dir} commit -a -m 'initial commit'`
    end

    def self.get_draft(user, num)
        draft = $drafts.find_one({:user => user, :num => num})
        return nil if draft.nil? 
        draft['content'] = File.open("#{draft['dir']}/draft.textile").read
        return self.new(user, draft['draft'], draft['content'])
    end

    def self.get_drafts(user)
        $drafts.find({:user => user}).to_a
    end
end
