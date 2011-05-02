require 'rubygems'
require 'logger'
require 'mechanize'
require 'json'

LOGIN_URL = 'https://www.tuenti.com/?m=Login&func=do_login'

logger =Logger.new(STDOUT)
logger.level = Logger::INFO
@m = Mechanize.new{|m| m.log = logger}

#si no se indica ususario y contrasenya salir
exit if ARGV.count != 2
user = ARGV[0]
pass = ARGV[1]

#inicializar la sesion conectandose a tuenti
@m.post(LOGIN_URL, {:email => user, :input_password => pass, :timezone => Time.now.utc_offset/3600})

#obtener la pagina con los enlaces a todos los albums.
#contiene el dato de cuantas fotos por album hay
album_links = @m.get("?m=Albums&func=index&ajax=1").links.select{|l| l.href =~ /Albums(.*?)photo_albums_page/}

#menu de seleccion de albums
begin
	for i in album_links.count.times do 
		puts "#{i+1} - #{album_links[i].text.strip}"
	end
	print "Elige una opcion: "
	option = STDIN.gets
end while option.to_i <= 0 or option.to_i > album_links.count

#seleccionar album a descargar
album = album_links[option.to_i - 1].node.to_s
album = album.scan(/click\('(.*?)'/).join()

#direccion base del album
album_page = @m.get(album)

#obtener variable auxiliar que sera la direccion base
#sobre la que obtener las urls de las paginas
#es posible que la variable no tenga valor si solo hay una pagina en el 
#album.
aux = album_page.search("a.next")[0].to_s.scan(/click\('(.*?)'/).join()

#si hay mas de una pagina cambiar valor a la variable album, sino (solo
#hay una pagina) no tocarla
unless aux.nil? or aux == ""
	album = aux
end

#obtener la cantidad de paginas que contiene el album
pages = album_page.search("span.active")[0].to_s.scan(/[0-9]+ de ([0-9]+)/).join().to_i

#si no hay numero de paginas usar el numero 1
pages = [pages, 1].max

#iterar sobre cada pagina
for page in pages.times

	#modificar la url del album para apuntar a la pagina actual
	album = album.sub(/photos_page=[0-9]+/, "photos_page=#{page}")

	#variable auxiliar con todos los links de la pagina actual
	links = @m.get(album).links

	#seleccionar aquellos enlaces que apuntan a una pagina de foto
	links = links.select{|l| l.href =~ /view_photo/}

	#array que contendra los enlaces a la pagina de cada foto,
	#no a la foto directamente
	photo_links = []

	#poner enlaces en el formato correcto. 
	#el enlace apunta a la pagina que contiene la imagen, no a la imagen directamente.
	links.each do |l|
		aux = l.href
		aux["#"] = "?"
		aux << "&ajax=1&store=1&ajax_target=canvas"

		photo_links << aux
	end

	#elminar enlaces repetidos
	photo_links.uniq!

	#iterar sobre los enlaces de las fotos de la pagina actual
	photo_links.each do |photo|
		#enlace que apunta directamente a la foto
		img = @m.get(photo).images.find{|i| i.node["id"] =~ /photo_image/}.url

		#arreglo para agregar extension jpg a las fotos que no tienen
		@m.get(img).save_as("#{URI.parse(img).path[1..-1]}" + ".jpg") unless img =~ /jpg$/
		@m.get(img).save if img =~ /jpg$/
		
		#reinicar la url base sobre la que se descarga, es necesario? otra forma de hacerlo?
		@m.get("http://www.tuenti.com")
	end
end
