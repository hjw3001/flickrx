require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('flickrx', '0.1.0') do |p|
  p.description    = "Ruby implementation of Flickr API."
  p.url            = "http://github.com/hjw3001/flickrx"
  p.author         = "Henry Wagner"
  p.email          = "hjw3001@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
