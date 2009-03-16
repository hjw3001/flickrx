require 'flickrx'
require 'c:/bat/WaldoFlickr'

# DailyFlickr.rb
#
# Randomly add a photo each time the program is run to the following Flickr groups
#
#  649122@N23 - The Anything Group...
#  67417927@N00 - anything and everything
#  76921467@N00 - Anything Goes!
#  86199631@N00 - Anything Goes :)
#  76649513@N00 - ANYTHING ALLOWED!!!!!!
#  38436807@N00 - the FlickrToday (only 1 pic per day)
#  95309787@N00 - Flickritis
#  34427469792@N01 -  FlickrCentral
#  33968254@N00 - Anything and Everything
#  96458800@N00 - Flickr Underappreciated (4 per day)

class DailyFlickr
  attr_accessor :group, :cache

  def initialize
    @group = Flickrx::Group.new
    waldo = WaldoFlickr.new
    @cache = waldo.cleanFilenames(waldo.loadCache)
  end

  def add_photos
    group.poolAdd(cache.random, '649122@N23')
    group.poolAdd(cache.random, '67417927@N00')
    group.poolAdd(cache.random, '76921467@N00')
    group.poolAdd(cache.random, '86199631@N00')
    group.poolAdd(cache.random, '76649513@N00')
    group.poolAdd(cache.random, '38436807@N00')
    group.poolAdd(cache.random, '95309787@N00')
    group.poolAdd(cache.random, '34427469792@N01')
    group.poolAdd(cache.random, '33968254@N00')
    group.poolAdd(cache.random, '96458800@N00')
    group.poolAdd(cache.random, '96458800@N00')
    group.poolAdd(cache.random, '96458800@N00')
    group.poolAdd(cache.random, '96458800@N00')
  end
  
end

class Array
   def random
      self[rand(self.length)]
   end
end

daily = DailyFlickr.new
daily.add_photos
