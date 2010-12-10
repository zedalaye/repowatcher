#!/usr/bin/ruby

class ParsableRepoInfo
  def check(directory)     
    Dir.chdir(directory) do |path|
      info = `#{@cmd}`
      info =~ @pattern ? $1 : nil
    end
  end
end

class SubversionRepoInfo < ParsableRepoInfo
  def initialize
    @cmd = 'svn info'
    @pattern = /^URL: (.*)$/
  end
end

class GitRepoInfo < ParsableRepoInfo
  def initialize
   @cmd = 'git remote -v'
   @pattern = /^\b.*\b\s(.*)\s\(fetch\)$/
  end
end

class MercurialRepoInfo
  def check(directory)
    Dir.chdir(directory) do |path|
      info = `hg paths default`
      info
    end
  end
end

class GClientRepoInfo
  def check(directory)
    Dir.chdir(directory) do |path|
      gclient = File.new('.gclient', 'r')
      info = gclient.read
      info =~ /^\s+"url"\s+:\s"(.*)",$/ ? $1 : nil
    end
  end
end

class RepoInfo
  def check(directory)
    config = File.join(directory, '.repo', 'manifests.git', 'config')
    if File.exists?(config)
      cfg = File.new(config, 'r')
      info = cfg.read
      info =~ /^\s+url\s=\s(.*)$/ ? $1 : nil
    end
  end
end

REPO = [
    { :name => 'GIT',        :file => '.git', :klass => GitRepoInfo }, 
    { :name => 'Subversion', :file => '.svn', :klass => SubversionRepoInfo }, 
    { :name => 'Mercurial',  :file => '.hg',  :klass => MercurialRepoInfo },
    { :name => 'DepotTools', :file => '.gclient', :klass => GClientRepoInfo },
    { :name => 'GoogleRepo', :file => '.repo', :klass => RepoInfo },
    { :name => 'BitBake',    :file => 'bitbake' },
    { :name => 'CVS',        :file => '.cvs' }
  ]

class RepositoryWalker
  attr_reader :repositories
  
  def initialize
    @repositories = Array.new
  end

  def walk(from)
    found_repo = nil
    REPO.each do |r|
      if File.exists?(File.join(from, r[:file]))
        found_repo = r.dup
        found_repo[:base] = from
        break
      end
    end

    if found_repo == nil
      list = Dir.glob(File.join(from, '*'))
      list.each do |d|
        if File.directory?(d)
          walk(d)    
        end
      end
    else
      unless found_repo[:klass].nil?
        manager = found_repo[:klass].new
        found_repo[:url] = manager.check(found_repo[:base])
        @repositories << found_repo
      end
    end
  end
end

if __FILE__ == $0
  ENV['LC_ALL'] = 'C'
  walker = RepositoryWalker.new
  walker.walk('.')
  walker.repositories.each do |r|
    puts "#{r[:base]} (#{r[:name]}) #{r[:url]}"
  end  
end
