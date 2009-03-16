require 'c:/bat/hwflickr'
require 'yaml'
require 'shorturl'
require 'twitter'

class SimpleUploader
  attr_reader :photo, :ps, :group, :uploader, :config, :twitter
  
  def initialize
    @photo = Photos.new
    @ps = PhotoSets.new
    @group = Group.new
    @uploader = Upload.new
    @config = load_config
    @twitter = create_or_find_config
  end
  
  def process
    # jpgfiles = File.join('./', "*.jpg")
    files = Dir.glob('*.jpg')

    photosets = ps.getList
    photoset = photosets[config['setname']]

    files.each { |filename|
      if (File.exists?(filename))
        begin
          #upload(filename)
          exp_hap = false
        rescue Exception
          puts "exception on #{filename} try again"
          print "An error occurred: ",$!, "\n"
          exp_hap = true
        end while exp_hap == true
      else
        puts "File #{filename} does not exist"
      end
    }
    
    # Create TinyURL
    tinyurl =  ShortURL.shorten("http://www.flickr.com/photos/henrywagner/sets/#{photoset['id']}/")

    # Post link to Twitter
    message = "added #{files.size} photos to Flickr set '#{config['setname']}' at #{tinyurl}"
    Twitter::Base.new(twitter['email'], twitter['password']).post(message)
  end

private

  def upload_file(filename)
    # If we already have a flickr id, the photo just needs to be replaced
    photoid = uploader.upload(filename, filename, config['description'], config['tags'], config['is_public'], config['is_friend'], config['is_family'])
    # If photoset doesn't exist, create it and add the photo as the set thumbnail
    if (photoset == nil)
      photoset = ps.create(config['setname'], nil, photoid).first
    # Otherwise, the photoset already exists, so just add the photo to it
    else
      ps.addPhoto(photoset['id'], photoid)        
    end
        
    #if (config['is_public'] == '1')
      # Add the photo to the default groups
      group.poolAdd(photoid, '20759249@N00') # 10 Million Photos
      group.poolAdd(photoid, '24772180@N00') #  1 day we'll have the most photos on Flickr
      group.poolAdd(photoid, '40275508@N00') # Please join
    #end
        
    puts photoid  
  end
  
  def load_config
    begin
      YAML::load open('data.yml')
    rescue
      puts "Trouble loading config"
    end
  end

  def create_or_find_config
    home = ENV['HOME'] || ENV['USERPROFILE'] || ENV['HOMEPATH']
    begin
      config = YAML::load open(home + "/.twitter")
    rescue
      puts "Trouble loading config"
    end          
  end
  
end

simple_uploader = SimpleUploader.new
simple_uploader.process
