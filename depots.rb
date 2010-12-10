#!/usr/bin/ruby

require 'rubygems'
require 'builder'

# Refines the File class
class File
  # Ensures that the path will include the File::SEPARATOR at its end
  def self.include_separator(path)
    path.chomp(SEPARATOR) + SEPARATOR
  end
end

# Base class for SCM that produces parsable output
class ParsableRepoInfo
  # Run the SCM command and extracts the URL using it's specific Regexp
  def check(directory)     
    Dir.chdir(directory) do |path|
      info = `#{@cmd}`
      info =~ @pattern ? $1 : nil
    end
  end
end

# Subversion repositories URL's are found in the output of svn info
class SubversionRepoInfo < ParsableRepoInfo
  def initialize
    @cmd = 'svn info'
    @pattern = /^URL: (.*)$/
  end
end

# Git repositories URL's are found in the output of git remote -v
class GitRepoInfo < ParsableRepoInfo
  def initialize
   @cmd = 'git remote -v'
   @pattern = /^\b.*\b\s(.*)\s\(fetch\)$/
  end
end

# Mercurial hg paths defaults gives the URL without need for extra parsing
class MercurialRepoInfo
  def check(directory)
    url = ''
    Dir.chdir(directory) do |path|
      url = `hg paths default`
    end
    url.chomp
  end
end

# Repositories managed by Google's GClient have a .gclient file
# .gclient is a python script containing an array of hashes but the
# URL can be easily retrieved.
class GClientRepoInfo
  def check(directory)
    url = ''
    Dir.chdir(directory) do |path|
      File.open('.gclient', 'r') do |f|
        info = f.read
        url = info =~ /^\s+"url"\s+:\s"(.*)",$/ ? $1 : nil
      end
    end
    url
  end
end

# Repositories managed by Google's repo have a .repo directory
# containing a bunch of files. The main URL is although stored
# in the manifests.git/config file (like any GIT repository)
class RepoInfo
  def check(directory)
    url = ''
    config = File.join(directory, '.repo', 'manifests.git', 'config')
    if File.exists?(config)
      File.open(config, 'r') do |f|
        info = f.read
        url = info =~ /^\s+url\s=\s(.*)$/ ? $1 : nil
      end
    end
    url
  end
end

# Array containing the supported repositories definitions
# We recognize the repository when the :file exists then we instanciate
# the :klass object to find the main URL
REPO = [
    { :name => 'GIT',        :file => '.git', :klass => GitRepoInfo }, 
    { :name => 'Subversion', :file => '.svn', :klass => SubversionRepoInfo }, 
    { :name => 'Mercurial',  :file => '.hg',  :klass => MercurialRepoInfo },
    { :name => 'DepotTools', :file => '.gclient', :klass => GClientRepoInfo },
    { :name => 'GoogleRepo', :file => '.repo', :klass => RepoInfo }
  ]

# Repository Walker search for repositories and is able to dump the
# found repositories in a XML file
class RepositoryWalker
  attr_reader :base_directory, :repositories
  
  def initialize(base_directory)
    @base_directory = File.expand_path(base_directory)
    @repositories = Array.new
  end

  def search_repositories
    walk(@base_directory)
  end

  def sort_repositories(key)
    @repositories.sort! { |a,b| a[key] <=> b[key] }
  end

  def dump(filename)
    xml = ""
    b = Builder::XmlMarkup.new(:target => xml, :indent => 2)
    b.instruct!
    b.projects(:root => @base_directory) do
      regexp = Regexp.new(File.include_separator(@base_directory))
      @repositories.each do |r|
        b.project(:scm => r[:name]) do
          b.url(r[:url])
          b.local(r[:base].gsub(regexp, ''))
        end
      end
    end
    File.open(filename, 'w') do |f|
      f.write(xml)
    end
  end

  private
  def walk(from)
    found_repo = nil
    REPO.each do |r|
      if File.exists?(File.join(from, r[:file]))
        found_repo = r.dup
        found_repo[:base] = File.expand_path(from)
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
    elsif not found_repo[:klass].nil?
      manager = found_repo[:klass].new
      found_repo[:url] = manager.check(found_repo[:base])
      @repositories << found_repo
    end
  end
end

if __FILE__ == $0
  # Setting LC_ALL=C ensures that Subversion output won't be translated
  ENV['LC_ALL'] = 'C'
  walker = RepositoryWalker.new('.')
  walker.search_repositories
  walker.sort_repositories(:base)
  walker.dump('projects.xml')
end
