# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flickrx}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Henry Wagner"]
  s.date = %q{2009-03-15}
  s.description = %q{Ruby implementation of Flickr API.}
  s.email = %q{hjw3001@gmail.com}
  s.executables = ["flickrxauthorize", "flickrxdaily", "flickrxmegaadd", "flickrxordersets", "flickrxuploader"]
  s.extra_rdoc_files = ["bin/flickrxauthorize", "bin/flickrxdaily", "bin/flickrxmegaadd", "bin/flickrxordersets", "bin/flickrxuploader", "lib/flickrx.rb", "lib/utils/AuthorizeFlickrx.rb", "lib/utils/DailyFlickr.rb", "lib/utils/MegaGroupAdd.rb", "lib/utils/OrderPhotosets.rb", "lib/utils/SimpleUploader.rb", "lib/utils/utils.rb", "README.rdoc"]
  s.files = ["bin/flickrxauthorize", "bin/flickrxdaily", "bin/flickrxmegaadd", "bin/flickrxordersets", "bin/flickrxuploader", "flickrx.gemspec", "init.rb", "lib/flickrx.rb", "lib/utils/AuthorizeFlickrx.rb", "lib/utils/DailyFlickr.rb", "lib/utils/MegaGroupAdd.rb", "lib/utils/OrderPhotosets.rb", "lib/utils/SimpleUploader.rb", "lib/utils/utils.rb", "Manifest", "Rakefile", "README.rdoc"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/hjw3001/flickrx}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Flickrx", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{flickrx}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby implementation of Flickr API.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
