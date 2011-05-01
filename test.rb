require 'rubygems'
require 'logger'
require 'mechanize'
require 'json'

LOGIN_URL = 'https://www.tuenti.com/?m=Login&func=do_login'
HOME_URL = 'http://www.tuenti.com/?m=home&func=view_home'
ALBUMS_URL = 'http://www.tuenti.com/?m=Search&func=get_user_custom_albums_for_data_source&ajax=1'

logger =Logger.new(STDOUT)
logger.level = Logger::INFO
@m = Mechanize.new{|m| m.log = logger}

exit if ARGV.count != 2
user = ARGV[0]
pass = ARGV[1]

@m.post(LOGIN_URL, {:email => user, :input_password => pass, :timezone => Time.now.utc_offset/3600})
#images = @m.get("?m=Albums&func=index&collection_key=3-60526335-5411208&ajax=1").images
images = @m.get("?m=Photo&func=view_photo&collection_key=3-60526335-5407593-705561026-60526335-1281373232&ajax=1&store=1&ajax_target=canvas").images
images.each{|i| @m.get(i.src).save}
