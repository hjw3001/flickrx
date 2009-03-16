require 'c:/bat/hwflickr'

photo = PhotoSets.new

photosets = photo.getList

ret = ''
#photosets.sort { |a,b| a.last['title']<=>b.last['title'] }
photosets.sort.each {|photoset| ret += "#{photoset.last['id']},"}
photo.orderSets(ret.chop)
