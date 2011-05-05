#!/usr/bin/ruby -w
require 'uri'
require 'resolv'
require 'net/http'
# This bit will be extracted out into a config file
dns_servers=["8.8.8.8","8.8.4.4"]
cloudfront_urls=[
  URI("http://d36jn9qou1tztq.cloudfront.net/static_war/render/css/packed/pack5.css.373145863781"),
  URI("http://d36jn9qou1tztq.cloudfront.net/static_war/render/css/packed/noaccessibility.css.426842630073"),
  URI("http://dwfwn5ehtp58w.cloudfront.net/static_war/render/css/packed/noaccessibility.css.426842630073")
]

class Dns
  def initialize
     @dns_cache=Hash.new{|hash,key| hash[key]=Hash.new}
  end
  def resolve(nameserver,host)
    cached_entry= @dns_cache[nameserver][host] 
    if (cached_entry.empty?) then
      cached_entry = Resolv::DNS.open({:nameserver=>nameserver}){|r| r.getaddresses(host).collect{|ip| ip.to_s}}
      puts "looked up #{host} at #{nameserver}"
      @dns_cache[nameserver][host] = cached_entry
    end
    cached_entry
  end
end

dns=Dns.new

# get the unique list of hostnames. 
#
hostnames = cloudfront_urls.collect{ |url| url.host}.uniq

# Make a list of lists of hostname=>IP
hosts_to_ips = hostnames.collect{ |host|
  [host,dns_servers.collect{|server| dns.resolve(server,host) }.flatten ]
}

#Make the cross-product of IPs and URLs
ips_to_urls = cloudfront_urls.collect { |url|
  (host,ips) = hosts_to_ips.find{|(host,ips)| host == url.host }
  ips.collect{ |ip| [ip,url]}
}.flatten(1)

## Fetch all the URLs for all of the IPs. 
##
results= ips_to_urls.collect{|(ip,url)|
    [url, Net::HTTP::start(ip,80){ |http| http.get(url.path,{"Host"=>url.host}).code} ]
}

p results

