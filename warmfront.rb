#!/usr/bin/ruby -w
require 'uri'
require 'resolv'
require 'net/http'

#
dns=["137.205.205.80","8.8.8.8","8.8.4.4"]
cloudfront_urls=[
  URI("http://d36jn9qou1tztq.cloudfront.net/static_war/render/css/packed/pack5.css.373145863781"),
  URI("http://d36jn9qou1tztq.cloudfront.net/static_war/render/css/packed/noaccessibility.css.426842630073")
]

# get the unique list of hostnames. Normally only one
#
hostnames = cloudfront_urls.map do |url|
  url.host
end.uniq

# Make a hash of hostname=>IP
hosts_to_ips = Hash.new
hostnames.each do |host|
  addresses=[]
  dns.each do |server| 
    Resolv::DNS.open({:nameserver=>server}) do |r|
      addresses += r.getaddresses(host)
    end
  end
  hosts_to_ips[host] = addresses.uniq
end

#Make a hash of IP=>URL to be fetched from that IP
ips_to_urls = Hash.new(Array.new)
cloudfront_urls.each do |url|
  puts "fetching #{url}"
  hosts_to_ips[url.host].each do |ip|
    ips_to_urls[ip] +=[url]
  end
end

# Fetch all the URLs for all of the IPs. 
#
ips_to_urls.each_key do |ip|
    puts "from #{ip} request..."
    ips_to_urls[ip].each do |url|
      Net::HTTP::start(ip.to_s,80)do |http|
         headers={"Host"=>url.host}
         res = http.get(url.path,headers )
         puts "#{url} #{res}"
      end
    end
end

