require 'nokogiri'
require 'open-uri'

# below code is added as a hack to remove server certificate error (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B:) for https sites
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
# the correct way is to add the certificates it can be done easily (google the above error)


class Scraper

	def getSingleProfile(url)

		user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.854.0 Safari/535.2"

		temp = {}

		temp[:profile_url] = url

		temp[:scraped_data] = {}

		# for proxy support in corporate networks
		
		# doc = Nokogiri::HTML(open(
		#   url, 
		#   :proxy_http_basic_authentication => ["http://proxy.foo.com:8000/", "proxy-user", "proxy-password"],
		#   # or for no authentication Nokogiri::HTML(open(url, :proxy => 'http://(ip_address):(port)'))
		#   'User-Agent' => user_agent
		# ))
		
		doc = Nokogiri::HTML(open(url, 'User-Agent' => user_agent))

		temp[:scraped_data][:main_info] = {}

		temp[:scraped_data][:main_info][:full_name] = fullname = doc.css('.full-name').text 
		temp[:scraped_data][:main_info][:headline] = doc.css('#headline').text								# headline/present industry
		temp[:scraped_data][:main_info][:industry] = doc.css('.industry').text								# kind of industry/ field
		temp[:scraped_data][:main_info][:home_town] = doc.css('#location .locality').text					# location as in hometown
		temp[:scraped_data][:main_info][:connections] = doc.css('.member-connections strong').first.text	# number of connections

		temp[:scraped_data][:profile_overview] = {}

		trs = doc.css('.profile-overview-content table tr')

		trs.each do |tr|
			key = tr['id'].split('-')
			key.shift
			temp[:scraped_data][:profile_overview][key.join('_').to_s] = tr.css('td').text  				# we need to check if list exists and get more info like urls also
		end

		temp[:scraped_data][:groups] = []

		groupElems = doc.css('#groups strong') if doc.css('#groups strong')									# checking if an element with that css tag exists or not

		groupElems.each do |el|
			temp[:scraped_data][:groups].push(el.text)
		end

		temp[:scraped_data][:organisations] = doc.css('.organization p').text.split(', ')

		temp[:scraped_data][:skills] = []

		skillElems = doc.css(".endorse-item-name") if doc.css(".endorse-item-name")

		skillElems.each do |el|
			temp[:scraped_data][:skills].push(el.text)
		end

		return temp
	end

	def getBulkProfiles(urls)

		temp = []

		max_num_urls_before_pausing = 10

		pause_time = 20

		urls.each do |url|

			profileInfo = self.getSingleProfile(url)

			temp.push(profileInfo)

			if (urls.index(url) + 1) % max_num_urls_before_pausing == 0								  	# if ten urls are scraped then wait for 20 seconds before resuming
				puts "sleeping for #{pause_time} sec"
				sleep(pause_time)
				puts "waking up after sleep"
			end

		end

		return temp

	end
end