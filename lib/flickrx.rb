##
# Ruby API for Flickr (See http://www.flickr.com/services/api/)
# (C) 2008 Henry Wagner
# http://www.henrywagner.org/

__AUTHOR__ = "Henry Wagner"
__VERSION__ = "0.1"
__DATE__ = "2008-05-02 21:55"

require 'cgi'
require 'md5'
require 'optparse'
require 'net/http'
require 'rexml/document'
require 'yaml'
include REXML

module Flickrx

class Utils
  def cleanString(source)
    if source == nil
      return
    elsif source == "N/A" then
      source = nil
    elsif source.count("\"") > 0 then
      list = source.split(/\"/)
      source = list[1]
    elsif source.count("/thumb") > 0 then
      list = source.split(/thumb/)
      source = list[0]
    end
    if (source != nil)
      source = CGI::unescapeHTML(source)
    end
    source
  end
  
  def fixFilename(source)
    if source.index('jpg') == nil then
      source = source + '.jpg'
    end
    source
  end
end

class Flickr

    @@template  = <<EOF
# .flickrx
# 
# Please fill in fields like this:
#
#  email: bla@bla.com
#  password: secret
#
api_key: 
secret: 
EOF

  attr_reader :config, :nsid, :username, :fullname

  def initialize
    @config = create_or_find_config
    @interface = 'http://www.flickr.com/services/rest/'
    @auth_url = 'http://flickr.com/services/auth/'
    @nsid = ''
    @username = ''
    @fullname = ''
  end

  def get_frob
    method = 'flickr.auth.getFrob'
    api_sig = _get_api_sig({'method' => method})
    data = _do_get(method, {
          'api_sig' => api_sig
        }
      )
      doc = Document.new(data)
      doc.elements.each('rsp/frob') { |frob|
      return frob.text
    }
  end

  ##
  # perms:
  #  'read', 'write', 'delete'
  ##
  def get_login_url(frob, perms='read')
    api_sig = _get_api_sig({'frob' => frob, 'perms' => perms});
    return "#{@auth_url}?api_key=#{@config['api_key']}&perms=#{perms}&frob=#{frob}&api_sig=#{api_sig}"
  end

  def get_token(frob)
    method = 'flickr.auth.getToken'
    api_sig = _get_api_sig({'frob' => frob, 'method' => method})
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'frob'    => frob
        }
      )
      doc = Document.new(data)
      doc.elements.each('rsp/auth') { |auth|
      token = auth.elements['token'].text
      user = auth.elements['user']
      @nsid = user.attributes['nsid']
      @username = user.attributes['username']
      @fullname = user.attributes['fullname']
      return token
    }
  end

  def _do_get(method, *params)
    params.each { |x, y|
      if y.class == Array then params[x] = y.join(y) end
    }
    url = "#{@interface}?api_key=#{@config['api_key']}&method=#{method}#{_urlencode(params)}"
    resp = Net::HTTP.get_response(URI.parse(url))
    doc = Document.new(resp.body.to_s)
    if doc.elements['rsp'].attributes['stat'] != 'ok'
      error_code = doc.elements['rsp'].elements['err'].attributes['code']
      error_msg = doc.elements['rsp'].elements['err'].attributes['msg']
      msg = "ERROR[#{error_code}]: #{error_msg}"
      p msg
      exit
    end
    resp.body.to_s
  end

  def _urlencode(params)
    ret = ''
    params.each { |param|
      param.each { |x, y|
        ret += "&#{x}=#{y}" unless "#{y}" == nil
      }
    }
    ret
  end

  def _get_api_sig(params)
    ret = ''
    params.sort.each { |x, y|
      ret += "#{x}#{y}" unless "#{y}" == nil
    }
    MD5.md5("#{@config['secret']}api_key#{@config['api_key']}#{ret}")
  end

  protected

  # Checks for the config, creates it if not found
  def create_or_find_config
    home = ENV['HOME'] || ENV['USERPROFILE'] || ENV['HOMEPATH']
    begin
      config = YAML::load open(home + "/.flickrx")
    rescue
      open(home + '/.flickrx','w').write(@@template)
      config = YAML::load open(home + "/.flickrx")
    end

    if config['api_key'] == nil or config['secret'] == nil
      puts "Please edit ~/.flickrx to include your flickr api_key and secret\nTextmate users: mate ~/.flickrx"
      exit(0)
    end

    config
  end

end

class Contacts < Flickr

  ##
  # filter:
  #  'friends', 'family', 'both', 'neither'
  ##
  def get_list(auth_token, filter='')
    method = 'flickr.contacts.getList'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => config['token'],
        'filter'  => filter
      }
    )
    data = _do_get(method,
          {
          'api_sig'  => api_sig,
          'auth_token'  => config['token'],
          'filter'  => filter
        }
      )
    doc = Document.new(data)
    contacts = []
    doc.elements.each('rsp/contacts/contact') { |contact|
      contacts << {
        'nsid'    => contact.attributes['nsid'],
        'username'  => contact.attributes['username'],
        'realname'  => contact.attributes['realname'],
        'friend'  => contact.attributes['friend'],
        'family'  => contact.attributes['family'],
        'ignored'  => contact.attributes['ignored']
        }
    }
    return contacts
  end

  def get_public_list(nsid)
    method = 'flickr.contacts.getPublicList'
    data = _do_get(method,
          {
          'api_key'  => config['api_key'],
          'user_id'  => nsid
        }
      )
      doc = Document.new(data)
      contacts = []
      doc.elements.each('rsp/contacts/contact') { |contact|
      contacts << {
        'nsid'    => contact.attributes['nsid'],
        'username'  => contact.attributes['username'],
        'ignored'  => contact.attributes['ignored']
      }
    }
    return contacts
  end
end

class Favorites < Flickr

  def add(auth_token, photo_id)
    method = 'flickr.favorites.add'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => config['token'],
        'photo_id'  => photo_id
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => config['token'],
          'photo_id'  => photo_id
        }
      )
    if data
      return true
    end
  end

  ##
  # extras: array that consists one or more of
  # license, date_upload, date_taken, owner_name, icon_server
  ##
  def get_list(auth_token, nsid='', extras=[], per_page=100, page=1)
    method = 'flickr.favorites.getList'
    api_sig = _get_api_sig(
        {
        'method'     => method,
        'auth_token' => config['token'],
        'user_id'    => nsid,
        'extras'     => extras.join(','),
        'per_page'   => per_page,
        'page'       => page
      }
    )
    data = _do_get(method,
        {
        'api_sig'    => api_sig,
        'auth_token' => config['token'],
        'user_id'    => nsid,
        'extras'     => extras.join(','),
        'per_page'   => per_page,
        'page'       => page
      }
    )
    doc = Document.new(data)
    photos = []
    doc.elements.each('rsp/photos/photo') { |photo|
      photos << {
        'id'          => photo.attributes['id'],
        'owner'       => photo.attributes['owner'],
        'ispublic'    => photo.attributes['ispublic'],
        'isfamily'    => photo.attributes['isfamily'],
        'isfriend'    => photo.attributes['isfriend'],
        'title'       => photo.attributes['title'],
        'license'     => photo.attributes['license'],
        'owner_name'  => photo.attributes['ownername'],
        'date_taken'  => photo.attributes['datetaken'],
        'date_upload' => photo.attributes['dateupload']
      }
    }
    return photos
  end

  ##
  # extras: array that consists one or more of
  # license, date_upload, date_taken, owner_name, icon_server
  ##
  def get_public_list(nsid, extras=[], per_page=100, page=1)
    method = 'flickr.favorites.getPublicList'
    data = _do_get(method,
        {
        'api_key'  => @config['api_key'],
        'user_id'  => nsid,
        'extras'   => extras.join(','),
        'per_page' => per_page,
        'page'     => page
      }
    )
    doc = Document.new(data)
    photos = []
    doc.elements.each('rsp/photos/photo') { |photo|
      photos << {
        'id'          => photo.attributes['id'],
        'owner'       => photo.attributes['owner'],
        'ispublic'    => photo.attributes['ispublic'],
        'isfamily'    => photo.attributes['isfamily'],
        'isfriend'    => photo.attributes['isfriend'],
        'title'       => photo.attributes['title'],
        'license'     => photo.attributes['license'],
        'owner_name'  => photo.attributes['ownername'],
        'date_taken'  => photo.attributes['datetaken'],
        'date_upload' => photo.attributes['dateupload']
      }
    }
    return photos
  end

  def remove(auth_token, photo_id)
    method = 'flickr.favorites.remove'
    api_sig = _get_api_sig(
        {
        'method'     => method,
        'auth_token' => config['token'],
        'photo_id'   => photo_id
      }
    )
    data = _do_get(method, {
          'api_sig'    => api_sig,
          'auth_token' => config['token'],
          'photo_id'   => photo_id
        }
      )
    if data
      return true
    end
  end
end

class Group < Flickr
  def poolAdd(photo_id, group_id)
          puts "Adding #{photo_id} to #{group_id}"
    method = 'flickr.groups.pools.add'
    api_sig = _get_api_sig(
        {
        'method'     => method,
        'auth_token' => config['token'],
        'photo_id'   => photo_id,
        'group_id'   => group_id
      }
    )
    data = _do_get(method, {
          'api_sig'    => api_sig,
          'auth_token' => config['token'],
          'photo_id'   => photo_id,
          'group_id'   => group_id
        }
      )
    if data
      return true
    end  
  end
end

class PhotoSets < Flickr

  def addPhoto(photoset_id, photo_id)
    method = 'flickr.photosets.addPhoto'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => config['token'],
        'photo_id'  => photo_id,
        'photoset_id'  => photoset_id
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => config['token'],
          'photo_id'  => photo_id,
          'photoset_id'  => photoset_id
        }
      )
    if data
      return true
    end
  end

  def create(title, description, primary_photo_id)
    method = 'flickr.photosets.create'
    if (description != nil)
      api_sig = _get_api_sig(
          {
          'method'    => method,
          'auth_token'    => config['token'],
          'primary_photo_id'  => primary_photo_id,
          'title'      => title,
          'description'    => description
        }
      )
      data = _do_get(method, {
            'api_sig'    => api_sig,
            'auth_token'    => config['token'],
            'primary_photo_id'  => primary_photo_id,
            'title'      => CGI::escape(title),
            'description'    => CGI::escape(description)
          }
        )
    else
      api_sig = _get_api_sig(
          {
          'method'    => method,
          'auth_token'    => config['token'],
          'primary_photo_id'  => primary_photo_id,
          'title'      => title
        }
      )
      data = _do_get(method, {
            'api_sig'    => api_sig,
            'auth_token'    => config['token'],
            'primary_photo_id'  => primary_photo_id,
            'title'      => CGI::escape(title)
          }
        )
    end
    doc = Document.new(data)
    photosets = []
    doc.elements.each('rsp/photoset') { |photoset|
      photosets << {
        'id'    => photoset.attributes['id']
      }
    }
    return photosets
  end

  def delete(auth_token, photoset_id)
    method = 'flickr.photosets.delete'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => auth_token,
        'photoset_id'  => photoset_id
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => auth_token,
          'photoset_id'  => photoset_id
        }
      )
    if data
      return true
    end
  end

  def getList(user_id = nil)
    method = 'flickr.photosets.getList'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => config['token'],
        'user_id'  => user_id
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => config['token'],
          'user_id'  => user_id
        }
    )

    doc = Document.new(data)
    photosets = Hash.new
    doc.elements.each('rsp/photosets/photoset') { |photoset|
      photosets[photoset.elements['title'].text] = {
        'id'    => photoset.attributes['id']
      }
      # photoset.attributes['id'] => photoset.elements['title'].text
    }
    return photosets
  end
  
  def orderSets(photosets)
    method = 'flickr.photosets.orderSets'
    api_sig = _get_api_sig(
        {
        'method'    => method,
        'auth_token'    => config['token'],
        'photoset_ids'    => photosets
      }
    )
    data = _do_get(method, {
          'api_sig'    => api_sig,
          'auth_token'    => config['token'],
          'photoset_ids'    => photosets
        }
      )
    if data
      return true
    end
  end

end

class Photos < Flickr

  def add_tags(auth_token, photo_id, tags)
    method = 'flickr.photos.addTags'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => auth_token,
        'photo_id'  => photo_id,
        'tags'    => tags.join(' ')
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => auth_token,
          'photo_id'  => photo_id,
          'tags'    => tags.join(' ')
        }
      )
    doc = Document.new(data)
    photos = []
    doc.elements.each('rsp/photos/photo') { |photo|
      photos << {
        'id'    => photo.attributes['id'],
        'owner'    => photo.attributes['owner'],
        'username'  => photo.attributes['username'],
        'title'    => photo.attributes['title']
      }
    }
    return photos
  end

  ##
  # max(count) = 50
  ##
  def get_contacts_photos(auth_token, count=10, just_friends=0, single_photo=0, include_self=0)
    method = 'flickr.photos.getContactsPhotos'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => auth_token,
        'count'    => count,
        'just_friends'  => just_friends,
        'single_photo'  => single_photo,
        'include_self'  => include_self
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => auth_token,
          'count'    => count,
          'just_friends'  => just_friends,
          'single_photo'  => single_photo,
          'include_self'  => include_self
        }
    )
    doc = Document.new(data)
    photos = []
    doc.elements.each('rsp/photos/photo') { |photo|
      photos << {
        'id'    => photo.attributes['id'],
        'owner'    => photo.attributes['owner'],
        'username'  => photo.attributes['username'],
        'title'    => photo.attributes['title']
      }
    }
    return photos
  end

  ##
  # max(count) = 50
  ##
  def get_contacts_public_photos(nsid, count=10, just_friends=0, single_photo=0, include_self=0)
    method = 'flickr.photos.getContactsPublicPhotos'
    data = _do_get(method, {
          'api_key'  => @config['api_key'],
          'user_id'  => nsid,
          'count'    => count,
          'just_friends'  => just_friends,
          'single_photo'  => single_photo,
          'include_self'  => include_self
        }
    )
    doc = Document.new(data)
    photos = []
    doc.elements.each('rsp/photos/photo') { |photo|
      photos << {
        'id'    => photo.attributes['id'],
        'owner'    => photo.attributes['owner'],
        'username'  => photo.attributes['username'],
        'title'    => photo.attributes['title']
      }
    }
    return photos
  end

  def get_favorites(photo_id)
    method = 'flickr.photos.getFavorites'
    data = _do_get(method, {
          'api_key'  => @config['api_key'],
          'photo_id'  => photo_id
        }
    )
    doc = Document.new(data)
    doc.elements.each('rsp/photo') { |photo|
      return {
        'id'    => photo.attributes['id'],
        'secret'  => photo.attributes['secret'],
        'server'  => photo.attributes['server'],
        'farm'    => photo.attributes['farm'],
        'page'    => photo.attributes['page'],
        'pages'    => photo.attributes['pages'],
        'perpage'  => photo.attributes['perpage'],
        'total'    => photo.attributes['total']
      }
    }
  end
  
  # <photo id="2477196681" secret="52159254f5" server="3293" farm="4">
  #  <exif tagspace="TIFF" tagspaceid="1" tag="271" label="Make">
  #   <raw>Canon</raw>
  #  </exif>
  #  <exif tagspace="TIFF" tagspaceid="1" tag="272" label="Model">
  #   <raw>Canon EOS 20D</raw>
  #   </exif>
  #  <exif tagspace="TIFF" tagspaceid="1" tag="274" label="Orientation">
  #   <raw>1</raw>
  #   <clean>Horizontal (normal)</clean>
  #  </exif>
  #  <exif tagspace="TIFF" tagspaceid="1" tag="306" label="Date and Time">
  #   <raw>2008:05:08 22:49:53</raw>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="33434" label="Exposure">
  #   <raw>30/1</raw>
  #   <clean>30 sec (30)</clean>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="33437" label="Aperture">
  #   <raw>71/10</raw>
  #   <clean>f/7.1</clean>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="34850" label="Exposure Program">
  #   <raw>1</raw>
  #   <clean>Manual</clean>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="34855" label="ISO Speed">
  #   <raw>100</raw>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="36867" label="Date and Time (Original)">
  #   <raw>2006:05:31 09:47:51</raw>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="37377" label="Shutter Speed">
  #   <raw>-4906891/1000000</raw>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="37378" label="Aperture">
  #   <raw>5655638/1000000</raw>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="37386" label="Focal Length">
  #   <raw>100/1</raw>
  #   <clean>100 mm</clean>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="40961" label="Color Space">
  #   <raw>1</raw>
  #   <clean>sRGB</clean>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="40962" label="Pixel X-Dimension">
  #   <raw>3504</raw>
  #  </exif>
  #  <exif tagspace="EXIF" tagspaceid="0" tag="40963" label="Pixel Y-Dimension">
  #   <raw>2336</raw>
  #  </exif>
  # </photo>
  def get_exif(photo_id)
    method = 'flickr.photos.getExif'
    api_sig = _get_api_sig(
        {
        'method'     => method,
        'auth_token' => config['token'],
        'photo_id'   => photo_id
      }
    )
    data = _do_get(method, {
          'api_sig'    => api_sig,
          'auth_token' => config['token'],
          'photo_id'   => photo_id
        }
      )
    doc = Document.new(data)
    doc.elements.each('rsp/photo') { |photo|
      exif_arr = []
      photos.elements.each('exif') { |exif|
        exif_arr << {
          'tagspace'   => exif.attributes['tagspace'],
          'tagspaceid' => exif.attributes['tagspaceid'],
          'tag'        => exif.attributes['tag'],
          'label'      => exif.attributes['label'],
          'raw'        => exif.elements['raw'].text,
          'clean'      => exif.elements['clean'].text
        }
      }
      return {
        'id'     => photo.attributes['id'],
        'secret' => photo.attributes['secret'],
        'server' => photo.attributes['server'],
        'farm'   => photo.attributes['farm'],
        'exif'   => exif_arr
      }
    }  
  end
  
  def get_info(photo_id)
    method = 'flickr.photos.getInfo'
    api_sig = _get_api_sig(
        {
        'method'     => method,
        'auth_token' => config['token'],
        'photo_id'   => photo_id
      }
    )
    data = _do_get(method, {
          'api_sig'    => api_sig,
          'auth_token' => config['token'],
          'photo_id'   => photo_id
        }
      )
    doc = Document.new(data)
    doc.elements.each('rsp/photo') { |photo|
      owner = photo.elements['owner']
      visibility = photo.elements['visibility']
      dates = photo.elements['dates']
      permissions = photo.elements['permissions']
      editability = photo.elements['editability']
      usage = photo.elements['usage']
      tags = photo.elements['tags']
      tags_arr = []
      photo.elements.each('tags/tag') { |tag|
        tags_arr << {
          'id'   => tag.attributes['id'],
          'text' => tag.text
        }
      }
      urls_arr = []
      photo.elements.each('urls/url') { |url|
        urls_arr << url.text
      }
      return {
        'id'             => photo.attributes['id'],
        'isfavorite'     => photo.attributes['isfavorite'],
        'license'        => photo.attributes['license'],
        'views'          => photo.attributes['views'],
        'media'          => photo.attributes['media'],
        'secret'         => photo.attributes['secret'],
        'server'         => photo.attributes['server'],
        'farm'           => photo.attributes['farm'],
        'title'          => photo.elements['title'].text,
        'description'    => photo.elements['description'].text,
        'owner_nsid'     => owner.attributes['nsid'],
        'owner_username' => owner.attributes['username'],
        'owner_realname' => owner.attributes['realname'],
        'owner_location' => owner.attributes['location'],
        'ispublic'       => visibility.attributes['ispublic'],
        'isfriend'       => visibility.attributes['isfriend'],
        'isfamily'       => visibility.attributes['isfamily'],
        'date_posted'    => dates.attributes['posted'],
        'date_taken'     => dates.attributes['taken'],
        'date_takengranularity'  => dates.attributes['takengranularity'],
        'date_lastupdate'        => dates.attributes['lastupdate'],
        'permission_permcomment' => permissions.attributes['permcomment'],
        'permission_permaddmeta' => permissions.attributes['permaddmeta'],
        'edit_cancomment'        => editability.attributes['cancomment'],
        'edit_canaddmeta'        => editability.attributes['canaddmeta'],
        'usage_candownload'      => usage.attributes['candownload'],
        'usage_canblog'          => usage.attributes['canblog'],
        'usage_canprint'         => usage.attributes['canprint'],
        'tags'                   => tags_arr,
        'urls'                   => urls_arr
      }
    }
  end

  # <sizes canblog="1" canprint="1" candownload="1">
  #   <size label="Square" width="75" height="75" source="<direct url to photo>" url="<url to flickr sizes page>" media="photo"/>
  #   <size label="Thumbnail" width="100" height="67" source="<direct url to photo>" url="<url to flickr sizes page>" media="photo"/>
  #   <size label="Small" width="240" height="160" source="<direct url to photo>" url="<url to flickr sizes page>" media="photo"/>
  #   <size label="Medium" width="500" height="333" source="<direct url to photo>" url="<url to flickr sizes page>" media="photo"/>
  #   <size label="Original" width="768" height="512" source="<direct url to photo>" url="<url to flickr sizes page>" media="photo"/>
  # </sizes>
  def get_sizes(photo_id)
    method = 'flickr.photos.getSizes'
    api_sig = _get_api_sig(
        {
        'method'     => method,
        'auth_token' => config['token'],
        'photo_id'   => photo_id
      }
    )
    data = _do_get(method, {
          'api_sig'    => api_sig,
          'auth_token' => config['token'],
          'photo_id'   => photo_id
        }
      )
    doc = Document.new(data)
    doc.elements.each('rsp/sizes') { |sizes|
      size_arr = []
      sizes.elements.each('size') { |size|
        size_arr << {
          'label'  => size.attributes['label'],
          'width'  => size.attributes['width'],
          'height' => size.attributes['height'],
          'source' => size.attributes['source'],
          'url'    => size.attributes['url'],
        }
      }
      
      return {
        'canblog'     => sizes.attributes['canblog'],
        'canprint'    => sizes.attributes['canprint'],
        'candownload' => sizes.attributes['candownload'],
        'sizes'       => size_arr
      }        
    }
  end
  
  def search(user_id, tags, tag_mode, page = 0, per_page = 500)
    method = 'flickr.photos.search'
    data = _do_get(method, {
          'api_key'  => @config['api_key'],
          'user_id'  => user_id,
          'tags'     => tags,
          'tag_mode' => tag_mode,
          'page'     => page,
          'per_page' => per_page
          
        }
    )
    doc = Document.new(data)
    photos = []
    doc.elements.each('rsp/photos/photo') { |photo|
      photos << {
        'id'     => photo.attributes['id'],
        'owner'  => photo.attributes['owner']
      }
    }
    return photos
  end

  def removeTag(auth_token, tag_id)
    method = 'flickr.photos.removeTag'
    api_sig = _get_api_sig(
        {
        'method'  => method,
        'auth_token'  => config['token'],
        'tag_id'  => tag_id
      }
    )
    data = _do_get(method, {
          'api_sig'  => api_sig,
          'auth_token'  => config['token'],
          'tag_id'  => tag_id
        }
      )
    if data
      return true
    end
  end

end

class People < Flickr

  def getPublicPhotos(user_id)
    method = 'flickr.people.getPublicPhotos'
    photos = []
    page = 1
    pages = 0
    
    # Find all the photos on all the pages
    begin
      data = _do_get(method, {
            'api_key'  => @config['api_key'],
            'user_id'  => user_id,
            'page'          => page

          }
      )
      doc = Document.new(data)
      doc.elements.each('rsp/photos') { |object|
        pages = object.attributes['pages']
        puts 'page ' + object.attributes['page'] + ' of ' + pages
      }
      doc.elements.each('rsp/photos/photo') { |photo|
        photos << {
          'id'       => photo.attributes['id'],
          'owner'    => photo.attributes['owner'],
          'secret'   => photo.attributes['secret'],
          'server'   => photo.attributes['server'],
          'farm'     => photo.attributes['farm'],
          'title'    => photo.attributes['title'],
          'ispublic' => photo.attributes['ispublic'],
          'isfriend' => photo.attributes['isfriend'],
          'isfamily' => photo.attributes['isfamily']
        }
      }
      page = page + 1
    end while page <= pages.to_i
    
    return photos
  end
  
end

class Upload < Flickr

  def _to_multipart(name, value)
    return "Content-Disposition: form-data; name=\"#{CGI::escape(name)}\"\r\n\r\n#{value}\r\n"
  end
  
  def _file_to_multipart(name, file, content)
    return "Content-Disposition: form-data; name=\"#{CGI::escape(name)}\"; filename=\"#{file}\"\r\n" +
        "Content-Transfer-Encoding: binary\r\n" +
        "Content-Type: image/jpeg\r\n\r\n" + content + "\r\n"
  end
  
  def _prepare_query(params)
    query = params.collect { |k, v|
      if v.respond_to?(:read)
        q = _file_to_multipart(k, v.path, v.read)
      else
        q = _to_multipart(k, v)
      end
      "--" + @boundary + "\r\n" + q 
    }.join("") + "--" + @boundary + "--"
    header = {"Content-type" => "multipart/form-data, boundary=" + @boundary + " "}
    return query, header
  end

  def upload(photo, title='', description='', tags='', is_public=1, is_friend=0, is_family=0)
    @flickr_host = 'www.flickr.com'
    @upload_action = '/services/upload/'
    @boundary = MD5.md5(photo).to_s
    file = File.new(photo, 'rb')
    api_sig = _get_api_sig(
        {
        'auth_token'  => config['token'],
        'title'       => title,
        'description' => description,
        'tags'        => tags,
        'is_public'   => is_public,
        'is_family'   => is_family,
        'is_friend'   => is_friend
      }
    )
    params = {
      'api_key'     => config['api_key'],
      'api_sig'     => api_sig,
      'auth_token'  => config['token'],
      'photo'       => file,
      'title'       => title,
      'description' => description,
      'tags'        => tags,
      'is_public'   => is_public,
      'is_family'   => is_family,
      'is_friend'   => is_friend
    }
    query, header = _prepare_query(params)
    file.close
    Net::HTTP.start(@flickr_host, 80) { |http|
            http.read_timeout = 10000
            http.open_timeout = 10000
      response = http.post(@upload_action, query, header)
      doc = Document.new(response.body)
      status = doc.elements['rsp'].attributes['stat']
      if status == "ok"
        photoid = doc.elements['rsp/photoid'].text
        return photoid
      else
        return false
      end
    }
  end

  def replace(photo, photo_id)
    @flickr_host = 'www.flickr.com'
    @upload_action = '/services/replace/'
    @boundary = MD5.md5(photo).to_s
    file = File.new(photo, 'rb')
    api_sig = _get_api_sig(
        {
        'auth_token'  => config['token'],
        'photo_id'  => photo_id
      }
    )
    params = {
      'api_key'  => config['api_key'],
      'api_sig'  => api_sig,
      'auth_token'  => config['token'],
      'photo'    => file,
      'photo_id'  => photo_id
    }
    query, header = _prepare_query(params)
    file.close
    Net::HTTP.start(@flickr_host, 80) { |http|
            http.read_timeout = 10000
            http.open_timeout = 10000
      response = http.post(@upload_action, query, header)
      doc = Document.new(response.body)
      status = doc.elements['rsp'].attributes['stat']
      if status == "ok"
        photoid = doc.elements['rsp/photoid'].text
        return photoid
      else
        return false
      end
    }
  end

end
end