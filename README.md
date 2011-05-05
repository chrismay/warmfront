A script for warming up cloudfront caches
=========================================

If you use Cloudfront as a cache onto your own servers, you'll have noticed that the first request for a resource
can be very slow, whilst Cloudfront fetches your content and stores it in S3 or whatever it is that it does.

So, when you push out new assets, you want to prime the caches by requesting each new asset. It's not enough to just do
a simple HTTP request, though, because each cloudfront host is handled by multiple different IP addresses. Moreover, the 
IP addresses you get back depend where in the world you make the DNS requests from.

So, we first make requests for each of our cloudfront hosts from as many public DNS servers around the world as we can find.
Once that's done, we request every cloudfront URL from every cloudfront IP that we've found. Hey presto, toasty-warm caches.
