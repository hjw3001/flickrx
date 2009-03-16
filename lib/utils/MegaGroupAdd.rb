require 'WaldoFlickr'

class MegaPhotoAdd
  attr_accessor :group, :cache

  def initialize
    @group = Group.new
    waldo = WaldoFlickr.new
    @cache = waldo.cleanFilenames(waldo.loadCache)
  end

  def add_all_public_photos
    cache.each_with_index {|photo, i| 
      puts i

      add_to_group(photo, '20759249@N00') # 10 Million Photos
      add_to_group(photo, '24772180@N00') #  1 day we'll have the most photos on Flickr
      add_to_group(photo, '40275508@N00') # Please join
    }
  end

  def add_to_group(photo_id, group_id)
    begin
      group.poolAdd(photo_id, group_id)
    rescue Exception
      puts "#{photo_id} already in group #{group_id}"
    end
  end
end

mega = MegaPhotoAdd.new
mega.add_all_public_photos
