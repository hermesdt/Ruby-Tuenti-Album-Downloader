require 'rubygems'
require 'logger'
require 'mechanize'

def recursive_download_album(photo_url)
  photo_page = M.get(photo_url)
  photo_img = photo_page.images.find{|i| i.node[:alt] =~ /Foto/}
  photo_file = thumb_to_real_photo(photo_img.src) if next_photo.href =~ /thumbs[0-9]\.images\.tuenti\.net/

  #download photo
  M.get(photo_file).save

  #next link
  next_photo = photo_page.links.find{|l| l.text =~ /Siguiente/}
  exit if next_photo.nil?

  recursive_download_album("http://m.tuenti.com/" + next_photo.href)
end

def thumb_to_real_photo(photo_url)
  tokens = photo_url.split("/")
  tokens = tokens[4..-1]
  tokens[3] = "600"

  real = "http://imagenes1.tuenti.net/"
  real << tokens.join("/")
  real
end


def thumb_to_real_photo2(photo_url)
  tokens = photo_url.split("/")
  tokens = tokens[4..-1]
  tokens[3] = "600"

  real = "http://imagenes1.tuenti.net/"
  real << tokens.join("/")
  real
end

logger =Logger.new(STDOUT)
logger.level = Logger::INFO
M = Mechanize.new{|m| m.log = logger}

exit if ARGV.count != 2
user = ARGV[0]
pass = ARGV[1]

login = M.get("http://m.tuenti.com")
login_form = login.forms.first
login_form.password = pass
login_form.tuentiemail = user

home = login_form.submit

a = "http://m.tuenti.com/?m=Photos&func=view_album_photo&collection_key=3-60526335-5407593-705564247-60526335-1281373569"

recursive_download_album(a)

