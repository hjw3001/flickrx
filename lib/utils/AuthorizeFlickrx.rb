require 'flickx'

photo = PhotoSets.new

frob = photo.get_frob
link = photo.get_login_url(frob, 'read')

puts
puts link
puts
puts "copy and paste the above url into your browser then hit enter after viewing the page"
gets

puts photo.get_token(frob)
