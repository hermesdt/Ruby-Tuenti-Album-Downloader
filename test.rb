require 'rubygems'
require 'logger'
require 'mechanize'

LOGIN_URL = 'https://www.tuenti.com/?m=Login&func=do_login'
HOME_URL = 'http://www.tuenti.com/?m=home&func=view_home'
ALBUMS_URL = 'http://www.tuenti.com/?m=Search&func=get_user_custom_albums_for_data_source&ajax=1'

def recursive_download_album(photo_url)
  photo_page = M.get(photo_url)
  photo_img = photo_page.images.find{|i| i.node[:alt] =~ /Foto/}

end


logger =Logger.new(STDOUT)
logger.level = Logger::INFO
M = Mechanize.new{|m| m.log = logger}

exit if ARGV.count != 2
user = ARGV[0]
pass = ARGV[1]

M.post(LOGIN_URL, {:email => user, :input_password => pass, :timezone => Time.now.utc_offset/3600})

puts M.get(HOME_URL).body
puts M.get(ALBUMS_URL).body

