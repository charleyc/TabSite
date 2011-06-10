require 'data_mapper'

TAB_DIRECTORY = File.join(File.dirname(__FILE__), "tabs")

DataMapper::Logger.new($stdout, :debug)

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/tabsite.db")

class Artist
  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :unique => true, :length => 1..50

  has n, :songs
end

class Song
  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :unique => :artist_id, :length => 1..75

  belongs_to :artist
  has n, :tab_files
end

class TabFile
  include DataMapper::Resource

  property :id,   Serial
  property :file, String
  # eventually add ratings, date added, etc

  belongs_to :song
  belongs_to :user
end

class User
  include DataMapper::Resource

  property :id, Serial
  property :username, String, :unique => true
  property :password, String #obviously this is dumb

  has n, :tab_files
end

DataMapper.finalize
DataMapper.auto_upgrade!

User.first_or_create(:username => "testaccount", :password => "")

class UIDError < StandardError; end
class ArtistError < StandardError; end
class SongError < StandardError; end

class TabManager
  def add(song_name, artist_name, tabfile, submitter)
    # song_name, artist_name: Strings containing the song and artist of tab, possibly badly formatted
    # tabfile: file object containing text of tab, possibly very large or otherwise ugly
    # submitter: id of submitter

    # current design is bad because it catches only one error at a time!

    song_name = song_name.strip
    artist_name = artist_name.strip # need to do logic to not have same artist with different
                                    # capitalization, etc
    user = User.get(submitter) # needs error-checking
    if !user
      raise BadUIDError, "Invalid UID"
    end

    artist = Artist.first(:name => artist)
    if !artist
      artist = Artist.new(:name => artist_name)
    end
    if !artist.valid?
      raise ArtistError, "Artist name invalid"
    end

    song = Song.first(:name => song_name, :artist => artist)
    if !song
      song = Song.new(:name => song_name, :artist => artist)
    end
    if !song.valid?
      raise SongError, "Song name invalid"
    end

    new_tab = TabFile.new(:title => title,
                          :artist => artist,
                          :song => song) 
    
    file_name = artist_name + " - " + title_name + ".txt"
    new_tab.file = file_name
    f = File.new(File.join(TAB_DIRECTORY, file_name), mode='w') # this is not the Ruby way to do this
  end
end

class LoginManager
  def initialize
    super
  end
  def validate(username, password)
    user = User.first(:username => username)
    puts "Value of user.nil? is #{user.nil?}"
    return user && (password == user.password) && user.id
  end
end
