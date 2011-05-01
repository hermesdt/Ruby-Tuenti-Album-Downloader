require 'rubygems'
require 'logger'
require 'mechanize'
require 'json'

LOGIN_URL = 'https://www.tuenti.com/?m=Login&func=do_login'
ALBUMS_URL = 'http://www.tuenti.com/?m=Search&func=get_user_custom_albums_for_data_source&ajax=1'

logger =Logger.new(STDOUT)
logger.level = Logger::INFO
@m = Mechanize.new{|m| m.log = logger}

exit if ARGV.count != 2
user = ARGV[0]
pass = ARGV[1]

@m.post(LOGIN_URL, {:email => user, :input_password => pass, :timezone => Time.now.utc_offset/3600})
album_links = @m.get("?m=Albums&func=index&ajax=1").links.select{|l| l.href =~ /Albums(.*?)photo_albums_page/}

begin
	for i in album_links.count.times do 
		puts "#{i+1} - #{album_links[i].text.strip}"
	end
	print "Elige una opcion: "
	option = STDIN.gets
end while option.to_i <= 0 or option.to_i > album_links.count

album = album_links[option.to_i - 1].node.to_s
album = album.scan(/click\('(.*?)'/).join()

album_page = @m.get(album)

puts album_page.body

aux = album_page.search("a.next")[0].to_s.scan(/click\('(.*?)'/).join()

unless aux.nil? or aux == ""
	album = aux
end


pages = album_page.search("span.active")[0].to_s.scan(/[0-9]+ de ([0-9]+)/).join().to_i
pages = [pages, 1].max

for page in pages.times

	#links = @m.get("?m=Albums&func=index&collection_key=3-60526335-5407593&photo_albums_page=1&ajax=1&store=1&ajax_target=canvas").links
	album = album.sub(/photos_page=[0-9]+/, "photos_page=#{page}")

	links = @m.get(album).links

	links = links.select{|l| l.href =~ /view_photo/}

	photo_links = []
	links.each do |l|
		aux = l.href
		aux["#"] = "?"
		aux << "&ajax=1&store=1&ajax_target=canvas"

		photo_links << aux
	end
	photo_links.uniq!


	photo_links.each do |photo|
		img = @m.get(photo).images.find{|i| i.node["id"] =~ /photo_image/}.url

		@m.get(img).save_as("#{URI.parse(img).path[1..-1]}" + ".jpg") unless img =~ /jpg$/
		@m.get(img).save if img =~ /jpg$/
		
		@m.get("http://www.tuenti.com")
	end
end
