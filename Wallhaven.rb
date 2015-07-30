# Wallhaven images scraper.
#
# This is an images scraper which aims to fetch all 4k images from the wallhaven site and download them on the desktop/srapingimages folder
#
# Author: Ahmed Mohamed Magdi
#

require "nokogiri"
require "open-uri"
require "find"
require "pathname"
require 'fileutils'

class Wallhaven
# ***************************************************************** #
# 							  Options								#
# ***************************************************************** #
	# Categories
	# 1: true
	# 0: false
		Categories = {'General':1 ,'Anime':1 ,'People':1}
	# Resolutions
	# Uncomment the needed resolutions, or leave all them commented for all resolutions
		Resolutions = 
		[	
			# '1024x768',
			# '1280x800',
			# '1366x768',
			# '1440x900',

			# '1600x900',
			# '1280x1024',
			# '1600x1200',
			# '1680x1050',

			# '1920x1080',
			# '1920x1200',
			# '2560x1440',
			# '2560x1600',

			# '3840x1080',
			# '5760x1080',
			# '3840x2160',
		]

	# Purity
	# 1: true
	# 0: false
		Purity 	= {'SFW':1, 'Sketchy':0}

	URL 	= "http://alpha.wallhaven.cc/search?categories=#{Categories[:General]}#{Categories[:Anime]}#{Categories[:People]}&purity=#{Purity[:SFW]}#{Purity[:Sketchy]}0&sorting=random&order=desc"
	FOLDER 	= "Wallhaven"
	PATH 	= Pathname.new("#{ENV['HOME']}/Desktop/#{FOLDER}")

	def self.run
		puts " ************************************************************************************** \nWelcome to Wallhaven images quick downloader.\nBefore start using this downloader, first configure it at your likness. \n\tChoose the preforable resolutions, purity and/or categories.\nAuthor: Ahmed Mohamed Magdi\n\n**************************************************************************************\n\n"
		puts "Loading Downloading Directory ..."

		Resolutions.each do |res|
			
		end

		validateFolderPath(PATH)
		puts "URL: #{URL}"
		begin
			main	
		rescue SystemExit, Interrupt => e
			puts "\nProgram terminated by user.\n"
		rescue Exception => e
			puts "\nProgram terminated due to an exception.\n"
		end
		
	end

	def self.main
		current_page = 1
		pages_count = 999999

		while current_page < pages_count
			#Fetch Data from site
			begin
				actual_URL = "#{URL}&page=#{current_page}"
				data = Nokogiri::HTML(open(actual_URL))	
			rescue Exception => e
				puts "No internet connection, or bad URL"
				exit
			end
			
			pages_count = Integer(data.xpath("//section[contains(@class,'thumb-listing-page')]/header").text.split("/")[1].strip)

			puts "Current Page: #{current_page}/#{pages_count}"
			puts "-----------------------------------------------------------"

			image_count = 1
			data.xpath("//ul/li/figure[contains(@class,'thumb')]/a/@href").map.each  do |url|
				fetch_image(url, current_page, image_count)
				image_count  = image_count + 1
			end
			puts "=========================================="
			current_page=current_page+1
		end
	end

	def self.validateFolderPath validation_path
		if !validation_path.exist?
		  puts "couldn't find #{validation_path} directory, creating directory ....."
		  FileUtils::mkdir_p validation_path
		  puts "Directory Successfuly created"
		else
		  puts "Directory Successfuly loaded"
		end
	end

	def self.fetch_image url, current_page, image_count
		puts "Acquiring Image Data ..."
		trials = 0
		begin
			# Fetching Image data
			trials+=1
			image_data = Nokogiri::HTML(open(url,:read_timeout => 60))	
		rescue Exception => e
			if trials < 3
				puts "Retrying to get data ... trial: #{trials}"
				retry 
			else 
				puts "Faild to get data, try again later"
				exit
			end
		end
		
		image_title = image_data.xpath("//main[contains(@id,'main')]/section[contains(@id,'showcase')]/img/@alt").text.strip
		image_url = "http:#{image_data.xpath("//main[contains(@id,'main')]/section[contains(@id,'showcase')]/img/@src").text}"

		puts "Data Successfuly Acquired \n\timage title: #{image_title}.jpg\n\timage page: #{current_page}\n\timage number: #{image_count}\n\timage URL: #{image_url}\n"

		image_width = image_data.xpath("//main[contains(@id,'main')]/section[contains(@id,'showcase')]/img/@data-wallpaper-width").text
		image_height = image_data.xpath("//main[contains(@id,'main')]/section[contains(@id,'showcase')]/img/@data-wallpaper-height").text
		image_category = image_title.split(" ").first

		image_path =  Pathname.new("#{PATH}/#{image_width}x#{image_height}/#{image_category}")
		validateFolderPath(image_path)

		if Find.find(image_path).grep(/#{image_title}/).count < 1
			# Download & saving Image
			puts "Acquiring #{image_title} ..."
			save_image(image_url,image_path, current_page, image_title, image_count)
			image_count  = image_count + 1
		else
			puts "Image already exists ... Skipping"
		end

		puts "-----------------------------------------------------------"
	end

	def self.save_image image_url,image_path, current_page, image_title, image_count
		download = open(image_url, :read_timeout => 60)
		puts "Image Successfuly Acquired, Saving Image ...."
		IO.copy_stream(download, "#{image_path}/#{current_page}-#{image_count} #{image_title}.jpg")
		puts "Image: #{image_title} -> downloaded and saved Successfuly"
	end
end

Wallhaven.run