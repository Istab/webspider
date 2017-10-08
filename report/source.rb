require "selenium-webdriver" # web browing driver

require_relative 'setup.rb'

implementation =	'Source code is written in ruby and powered by Selenium'\
					' WebDriver gem and geckodriver which allow visiting'\
					' pages in real firefox browser. First, driver visit'\
					' seed urls and gather valid links from the pages.'\
					' Then, start building this report in real time while'\
					' visiting all collected urls. During each visit,'\
					' the driver saves the source code locally and score'\
					' its relevance to the topic by counting how many related'\
					' terms appeared in the source code of the page.'\
					' Finally, output all results to the report page.'

table_headers = ['Link Name', 'URL', 'Page Title', 'Source Code', 'Relevance']					

links = []

driver = Selenium::WebDriver.for :firefox

# Get links from seeds
SEEDS.each do |url|
	driver.navigate.to url
	driver.find_elements(tag_name: 'a').each do |link|
		if link.attribute('href') && link.attribute('href').start_with?('http')
			links << {url: link.attribute('href'), name: link.text, score: 0}
		end
	end
end

report_output = File.new('report.html', 'w')
report_output.puts '<html><head><title>Report</title></head><body>'
report_output.puts "<b>Topic:</b> #{TOPIC}<br/><br/><b>related terms:</b><ul>"
TERMS.each{|term| report_output.puts "<li>#{term}</li><br/>"}
report_output.puts '</ul><b>Seed URLs:</b><br/><ul>'
SEEDS.each{|seed_url| report_output.puts "<li>#{seed_url}</li><br/>"}
report_output.puts "</ul><br/><b>Implementation:</b> #{implementation}<br/>"
report_output.puts "<br/><b># of crawled pages:</b> #{links.count}<br/><br/>"
report_output.puts '<b>Results:</b><br/><table><tr>'
table_headers.each{|header| report_output.puts "<th>#{header}</th>"}
report_output.puts '</tr>'

links.each_with_index do |link, index|
	driver.navigate.to link[:url]

	# Score each link on relevance	
	TERMS.each do |term|
		link[:score]+=1 if driver.page_source.downcase.include?(term)
		link[:title]= driver.title
		link[:local_path] =
			"../crawled_pages/#{index}_#{link[:title].gsub(/[\|\\\?\/]/, '')}.html"
	end
	
	# Save the page
	page_output = File.new(link[:local_path], 'w')
	page_output.puts driver.page_source
	page_output.close
	
	# Output results to report
	report_output.puts 	"<tr><td>#{link[:name]}</td><td>#{link[:url]}</td>"\
						"<td>#{link[:title]}</td><td>#{link[:local_path]}</td>"\
						"<td>#{link[:score]}</td></tr>"
end
report_output.puts '</table></body><html>'
report_output.close