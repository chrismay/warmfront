#!/usr/bin/ruby -w
require 'uri'
require 'resolv'
require 'net/http'
require 'yaml'

# This bit will be extracted out into a config file
config=YAML.load(File.open("config.yaml"))

cloudfront_urls=config[:urls].collect{|u| URI(u)}


# cache DNS lookups so we don't have to hammer the DNS, or tie ourselves in knots trying to lookup only once per host
class Dns
  def initialize
     @dns_cache=Hash.new{|hash,key| hash[key]=Hash.new}
  end
  def resolve(nameserver,host)
    @dns_cache[nameserver][host] ||= 
      Resolv::DNS.open({:nameserver=>nameserver}){|r| r.getaddresses(host).collect{|ip| ip.to_s}}
  end
end

dns=Dns.new

url_to_ips = cloudfront_urls.collect{|url|
  [url,config[:dns_servers].collect{|server| dns.resolve(server,url.host)}.flatten]
}

results = url_to_ips.collect{|(url,ips)| ips.collect{|ip|
  [url.to_s,ip,Net::HTTP::start(ip,80){ |http| http.get(url.path,{"Host"=>url.host}).code}]
}}.flatten(1)
# need the flatten because I can't find a way to do flatmap / collect_concat in ruby 1.8

results.each{|url, ip, response| puts "#{url} returned #{response} from #{ip}"}

