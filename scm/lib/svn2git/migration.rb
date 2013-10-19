require 'optparse'
require 'pp'

module Svn2Git
  DEFAULT_AUTHORS_FILE = "~/.svn2git/authors"

  class Migration

    attr_reader :dir

    def initialize(args)
      @options = parse(args)
      if @options[:rebase]
         show_help_message('Too many arguments') if args.size > 0
         verify_working_tree_is_clean
      elsif @options[:rebasebranch]
         show_help_message('Too many arguments') if args.size > 0
         verify_working_tree_is_clean
      else
         show_help_message('Missing SVN_URL parameter') if args.empty?
         show_help_message('Too many arguments') if args.size > 1
         @url = args.first
      end
    end

    def run!
      if @options[:rebase]
        get_branches
      elsif @options[:rebasebranch]
        get_rebasebranch
      else
        clone!
      end
      fix_branches unless @options[:branches].nil?
      fix_tags unless @options[:tags].nil?
      fix_trunk unless @options[:trunk].nil?
      optimize_repos
    end

    def parse(args)
      # Set up reasonable defaults for options.
      options = {}
      options[:verbose] = false
      options[:metadata] = false
      options[:nominimizeurl] = false
      options[:rootistrunk] = false
      options[:trunk] = 'trunk'
      options[:branches] = []
      options[:tags] = []
      options[:exclude] = []
      options[:revision] = nil
      options[:username] = nil
      options[:rewriteroot] = nil
      options[:rebasebranch] = false

      if File.exists?(File.expand_path(DEFAULT_AUTHORS_FILE))
        options[:authors] = DEFAULT_AUTHORS_FILE
      end


      # Parse the command-line arguments.
      @opts = OptionParser.new do |opts|
        opts.banner = 'Usage: svn2git SVN_URL [options]'

        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('--rebase', 'Instead of cloning a new project, rebase an existing one against SVN') do
          options[:rebase] = true
        end

        opts.on('--username NAME', 'Username for transports that needs it (http(s), svn)') do |username|
          options[:username] = username
        end

        opts.on('--trunk TRUNK_PATH', 'Subpath to trunk from repository URL (default: trunk)') do |trunk|
          options[:trunk] = trunk
        end

        opts.on('--branches BRANCHES_PATH', 'Subpath to branches from repository URL (default: branches)') do |branches|
          options[:branches] << branches
        end

        opts.on('--tags TAGS_PATH', 'Subpath to tags from repository URL (default: tags)') do |tags|
          options[:tags] << tags
        end

        opts.on('--rootistrunk', 'Use this if the root level of the repo is equivalent to the trunk and there are no tags or branches') do
          options[:rootistrunk] = true
          options[:trunk] = nil
          options[:branches] = nil
          options[:tags] = nil
        end

        opts.on('--notrunk', 'Do not import anything from trunk') do
          options[:trunk] = nil
        end

        opts.on('--nobranches', 'Do not try to import any branches') do
          options[:branches] = nil
        end

        opts.on('--notags', 'Do not try to import any tags') do
          options[:tags] = nil
        end

        opts.on('--no-minimize-url', 'Accept URLs as-is without attempting to connect to a higher level directory') do
          options[:nominimizeurl] = true
        end

        opts.on('--revision START_REV[:END_REV]', 'Start importing from SVN revision START_REV; optionally end at END_REV') do |revision|
          options[:revision] = revision
        end

        opts.on('-m', '--metadata', 'Include metadata in git logs (git-svn-id)') do
          options[:metadata] = true
        end

        opts.on('--authors AUTHORS_FILE', "Path to file containing svn-to-git authors mapping (default: #{DEFAULT_AUTHORS_FILE})") do |authors|
          options[:authors] = authors
        end

        opts.on('--rewrite-root URL', "Use --rewrite-root=URL option to git svn init (see git svn docs); implies --metadata") do |rewriteroot|
          options[:rewriteroot] = rewriteroot
          options[:metadata] = true
        end

        opts.on('--exclude REGEX', 'Specify a Perl regular expression to filter paths when fetching; can be used multiple times') do |regex|
          options[:exclude] << regex
        end

        opts.on('-v', '--verbose', 'Be verbose in logging -- useful for debugging issues') do
          options[:verbose] = true
        end

        opts.on('--rebasebranch REBASEBRANCH', 'Rebase specified branch.') do |rebasebranch|
          options[:rebasebranch] = rebasebranch
        end

        opts.separator ""

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
      end

      @opts.parse! args

      # Set default branches and tags if not explicitely configured
      if ! options[:branches].nil? && options[:branches].length == 0 
        options[:branches] << 'branches'
      end
      if ! options[:tags].nil? && options[:tags].length == 0 
        options[:tags] << 'tags'
      end

      options
    end

  private

    def clone!
      trunk = @options[:trunk]
      branches = @options[:branches]
      tags = @options[:tags]
      metadata = @options[:metadata]
      nominimizeurl = @options[:nominimizeurl]
      rootistrunk = @options[:rootistrunk]
      authors = @options[:authors]
      exclude = @options[:exclude]
      revision = @options[:revision]
      username = @options[:username]
      rewriteroot = @options[:rewriteroot]

      if rootistrunk
        # Non-standard repository layout.  The repository root is effectively 'trunk.'
        cmd = "git svn init --prefix=svn/ "
        cmd += "--username=#{username} " unless username.nil?
        cmd += "--no-metadata " unless metadata
        cmd += "--rewrite-root=#{rewriteroot} " unless rewriteroot.nil?
        if nominimizeurl
          cmd += "--no-minimize-url "
        end
        cmd += "'--trunk=#{@url}'"
      unless exclude.empty?
        # Add exclude paths to the command line; some versions of git support
        # this for fetch only, later also for init.
        regex = []
        unless rootistrunk
          regex << "#{trunk}[/]" unless trunk.nil?
            tags = tags.join('|') unless tags.nil?
            branches = branches.join('|') unless tags.nil?
          
          regex << "#{tags}[/][^/]+[/]" unless tags.nil?
          regex << "#{branches}[/][^/]+[/]" unless branches.nil?
        end
        regex = '^(?:' + regex.join('|') + ')(?:' + exclude.join('|') + ')'
        cmd += "'--ignore-paths=#{regex}' "
      end
        run_command(cmd, true, true)

      else
        cmd = "git svn init --prefix=svn/ "

        # Add each component to the command that was passed as an argument.
        cmd += "--username=#{username} " unless username.nil?
        cmd += "--no-metadata " unless metadata
        cmd += "--rewrite-root=#{rewriteroot} " unless rewriteroot.nil?
        if nominimizeurl
          cmd += "--no-minimize-url "
        end
        cmd += "--trunk=#{trunk} " unless trunk.nil?
        tags.each do |tags|
          cmd += "--tags=#{tags} "
        end unless tags.nil?
        branches.each do |branches|
          cmd += "--branches=#{branches} "
        end unless branches.nil?
      unless exclude.empty?
        # Add exclude paths to the command line; some versions of git support
        # this for fetch only, later also for init.
        regex = []
        unless rootistrunk
          regex << "#{trunk}[/]" unless trunk.nil?
            tags = tags.join('|') unless tags.nil?
            branches = branches.join('|') unless tags.nil?
          
          regex << "#{tags}[/][^/]+[/]" unless tags.nil?
          regex << "#{branches}[/][^/]+[/]" unless branches.nil?
        end
        regex = '^(?:' + regex.join('|') + ')(?:' + exclude.join('|') + ')'
        cmd += "'--ignore-paths=#{regex}' "
      end

        cmd += "\'#{@url}\'"

        run_command(cmd, true, true)
      end

      run_command("git config --local svn.authorsfile #{authors}") unless authors.nil?

      cmd = "git svn fetch "
      unless revision.nil?
        range = revision.split(":")
        range[1] = "HEAD" unless range[1]
        cmd += "-r #{range[0]}:#{range[1]} "
      end

      # add user name here to force git svn to ask for the same username as
      # the one used for initializing the repo.
      cmd += "--username=#{username} " unless username.nil?

      run_command(cmd, true, true)

      get_branches
    end

    def get_branches
      # Get the list of local and remote branches, taking care to ignore console color codes and ignoring the
      # '*' character used to indicate the currently selected branch.
      @local = run_command("git branch -l --no-color").split(/\n/).collect{ |b| b.gsub(/\*/,'').strip }
      @remote = run_command("git branch -r --no-color").split(/\n/).collect{ |b| b.gsub(/\*/,'').strip }

      # Tags are remote branches that start with "tags/".
      @tags = @remote.find_all { |b| b.strip =~ %r{^svn\/tags\/} }

    end

    def get_rebasebranch
	  get_branches 
	  @local = @local.find_all{|l| l == @options[:rebasebranch]}
	  @remote = @remote.find_all{|r| r.include? @options[:rebasebranch]}

      if @local.count > 1 
        pp "To many matching branches found (#{@local})."
        exit 1
      elsif @local.count == 0
	    pp "No local branch named \"#{@options[:rebasebranch]}\" found."
        exit 1
      end

      if @remote.count > 2 # 1 if remote is not pushed, 2 if its pushed to remote
        pp "To many matching remotes found (#{@remotes})"
        exit 1
      elsif @remote.count == 0
	    pp "No remote branch named \"#{@options[:rebasebranch]}\" found."
        exit 1
      end
	  pp "Local branches \"#{@local}\" found"
	  pp "Remote branches \"#{@remote}\" found"

      @tags = [] # We only rebase the specified branch

    end

    def fix_tags
      current = {}
      current['user.name']  = run_command("git config --local --get user.name", false)
      current['user.email'] = run_command("git config --local --get user.email", false)

      @tags.each do |tag|
        tag = tag.strip
        id      = tag.gsub(%r{^svn\/tags\/}, '').strip
        subject = run_command("git log -1 --pretty=format:'%s' \"#{escape_quotes(tag)}\"").chomp("'").reverse.chomp("'").reverse
        date    = run_command("git log -1 --pretty=format:'%ci' \"#{escape_quotes(tag)}\"").chomp("'").reverse.chomp("'").reverse
        author  = run_command("git log -1 --pretty=format:'%an' \"#{escape_quotes(tag)}\"").chomp("'").reverse.chomp("'").reverse
        email   = run_command("git log -1 --pretty=format:'%ae' \"#{escape_quotes(tag)}\"").chomp("'").reverse.chomp("'").reverse
        run_command("git config --local user.name \"#{escape_quotes(author)}\"")
        run_command("git config --local user.email \"#{escape_quotes(email)}\"")

        original_git_committer_date = ENV['GIT_COMMITTER_DATE']
        ENV['GIT_COMMITTER_DATE'] = escape_quotes(date)
        run_command("git tag -f -a -m \"#{escape_quotes(subject)}\" \"#{escape_quotes(id)}\" \"#{escape_quotes(tag)}\"")
        ENV['GIT_COMMITTER_DATE'] = original_git_committer_date

        run_command("git branch -d -r \"#{escape_quotes(tag)}\"")
      end

    ensure
      # We only change the git config values if there are @tags available.  So it stands to reason we should revert them only in that case.
      unless @tags.empty?
        current.each_pair do |name, value|
          # If a line was read, then there was a config value so restore it.
          # Otherwise unset the value because originally there was none.
          if value.strip != ''
            run_command("git config --local #{name} \"#{value.strip}\"")
          else
            run_command("git config --local --unset #{name}")
          end
        end
      end
    end

    def fix_branches
      svn_branches = @remote - @tags
      svn_branches.delete_if { |b| b.strip !~ %r{^svn\/} }

      if @options[:rebase]
        trunk = @options[:trunk]
        branches = @options[:branches]
        tags = @options[:tags]
        metadata = @options[:metadata]
        nominimizeurl = @options[:nominimizeurl]
        rootistrunk = @options[:rootistrunk]
        authors = @options[:authors]
        exclude = @options[:exclude]
        revision = @options[:revision]
        username = @options[:username]
        rewriteroot = @options[:rewriteroot]
          
        cmd = "git svn fetch "
        unless revision.nil?
            range = revision.split(":")
            range[1] = "HEAD" unless range[1]
            cmd += "-r #{range[0]}:#{range[1]} "
        end

        # add user name here to force git svn to ask for the same username as
        # the one used for initializing the repo.
        cmd += "--username=#{username} " unless username.nil?

        run_command(cmd, true, true)
      end

      svn_branches.each do |branch|
        branch = branch.gsub(/^svn\//,'').strip
        if @options[:rebase] && (@local.include?(branch) || branch == 'trunk') && !(branch == 'trunk' && @options[:trunk].nil?)
           lbranch = branch
           lbranch = 'master' if branch == 'trunk'
           run_command("git checkout -f \"#{lbranch}\"")
           run_command("git rebase \"remotes/svn/#{branch}\"")
           next
        end

        next if branch == 'trunk' || @local.include?(branch)
        run_command("git branch --track \"#{branch}\" \"remotes/svn/#{branch}\"")
        run_command("git checkout \"#{branch}\"")
      end
    end

    def fix_trunk
      trunk = @remote.find { |b| b.strip == 'trunk' }
      if trunk && ! @options[:rebase]
        run_command("git checkout svn/trunk")
        run_command("git branch -D master")
        run_command("git checkout -f -b master")
      else
        run_command("git checkout -f master")
      end
    end

    def optimize_repos
      run_command("git gc")
    end

    def run_command(cmd, exit_on_error=true, printout_output=false)
      log "Running command: #{cmd}"

      ret = ''

      cmd = "2>&1 #{cmd}"
      IO.popen(cmd) do |stdout|
        if printout_output
          stdout.each_char do |character|
            $stdout.print character
            ret << character
          end
        else
          stdout.each do |line|
            log line
            ret << line
          end
        end
      end

      if exit_on_error && ($?.exitstatus != 0)
        $stderr.puts "command failed:\n#{cmd}"
        exit -1
      end

      ret
    end

    def log(msg)
      puts msg if @options[:verbose]
    end

    def show_help_message(msg)
      puts "Error starting script: #{msg}\n\n"
      puts @opts.help
      exit
    end

    def verify_working_tree_is_clean
      status = run_command('git status --porcelain --untracked-files=no')
      unless status.strip == ''
        puts 'You have local pending changes.  The working tree must be clean in order to continue.'
        exit -1
      end
    end

    def escape_quotes(str)


      #str.gsub("'", "'\\\\''").gsub('"', '\\\\"')
      str.gsub(/'|"/) { |c| "\\#{c}" }

    end
  end
end

