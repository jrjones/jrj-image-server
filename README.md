jrj-image-server
================

A simple image server that handles dynamic resizing of images for use as an origin 
server to a cache like Amazon's CloudFront.

![jrj-image-server logo](http://image.jrj.org/resized.cfm/w150/jrj-image-server-logo.png)

License
=======
Copyright (c) 2012, Joseph R. Jones (jrj.org) Licensed under the MIT License. 

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

What it does
================
This is a very basic image server, implemented in ColdFusion, which acts as an origin 
server for a cache. It allows you to quickly and easily resize images based on requests 
and let the result be cached.

The image resizing is slow-- this is NOT intended to be run on a front-end web server. The
idea is to use as the origin server for a cache-- like, for example, [Amazon CloudFront]
(http://aws.amazon.com/cloudfront/)

You just bake in an image tag with a source of
http://myimagecache.domain.com/resized.cfm/w300/h400/filename.jpg where filename.jpg 
is the name of an image file in the root, and **wXXX** and **hXXX** "directory" names
control the height and width of the resulting image.

It will show a file-not-found image if the specified file isn't in the directory, and
will show a file-not-valid image if the specified file cannot be parsed.

![404 Image](http://image.jrj.org/resized.cfm/w200/file-that-doesnt-exist.jpg)

Demo Site
=========
You can view a live demo here:
http://image.jrj.org/test.cfm

Why do I need an image server?
==============================
Compared with most datatypes served by your web server, images are huge... and if your web
site is like mine, there are a lot of them. They are second only to video in size, but 
most video these days is served via services like YouTube and Vimeo, so you don't have to
deal with video files very often. 

More importantly, supporting *responsive web design* means that images must frequently be
resized. You'll need thumbnails ad often a couple of additional resolutions/sizes of each
image to support your application. You can create and store each of these manually, but
the amount of work involved to do that really adds up. (Quick math problem... if your
site has 100 images, but you need a thumbnail and 3 sizes to support your reactive web
design, now you're storing 400 images.)

Obviously, you could just use height and width tags in your HTML, but that means you're 
sending down more data than is needed for the displayed size, which chews through more
bandwidth (read: cost) and increases load times for your web site.

I built jrj-image-server for my old blog-- the idea was that I would store a single, 
high-resolution version of all the images in a folder, but would reference them with a 
more expressive URL so that an appropriately sized image is returned.

	<img src="http://www.jrj.org/resized.cfm/w600/somepicture.jpg">

This will return the somepicture.jpg file, but will first resize it to a maximum width of
600 pixels. So even if the original file is a massive, multi-megapixel image, I'll only
send the browser the pixels it needs. (If the original image had a width of 600 pixels
or less, I'd just send the original image and let the browser scale it.)

The issue with this type of approach, of course, is that resizing images is an expensive
operation-- you don't want to do this for every request. Enter a caching server.

A cache server-- I use Amazon's excellent and affordable CloudFront server-- will accept
all of these requests, and cache the result. So when that 600 pixel image is requested
for the first time it's resized, but CloudFront stores the result so that I never have
to resize it again. My "origin server" contains all of the original files and the resize
code, but doesn't have to store any of the resized images. 

CloudFront will distribute cached copies of the resized images to the "edge" of the
network, with nodes across a massive global network. This means not only does your server
have to serve fewer http requests, but your users get much faster, lower-latency response
from an more geographically proximate edge server. 

Another use for the image server (and the reason I am updating it) is to make it easy
to serve super-high resolution images to high-DPI displays like the iPad 3 and future
devices without making your image workflow harder. You are still just creating one image
and deciding the final output size in your HTML and JavaScript.

Setting up CloudFront for use with jrj-image-server
===================================================
This system should be compatible with just about any caching service, but since CloudFront
is so easy and inexpensive to get up and running (and because it's what I'm familiar with)
I'll provide a brief overview here.

CloudFront is really designed to distribute content stored in Amazon S3 buckets, but it
works just as well with a non-S3 origin server. 

Go to the [Amazon Web Services management console] (http://aws.amazon.com) and log in.

Click on the "CloudFront" tab, and click on "Create Distribution."

This will provide you with a simple wizard for creating a new CloudFront distribution. All
you have to do is provide the hostname of your origin server, and select "match viewer" 
under protocol policy. The rest of the default settings should be fine, though obviously
you can tweak further for your needs.

Once the disribution is set up, you will get back a hostname to use, something along the 
lines of XXX.cloudfront.net (where XXX is a random string of letters and numbers.)

You can optionally set up a friendlier CNAME - like, for example, I used to use 
"image.jrj.org" for my image cache.

Now you just use an image tag like the one below:

	<img src="http://image.jrj.org/resized.cfm/w600/somepicture.jpg">

The browser will request that file from CloudFront. If it's already on one of the edge
servers the browser will get a really fast response. If it's a URL that's never been
requested before, then CloudFront will make a request to your origin server, and the 
result will be cached for future requests. Nice and simple!

What types of image resizing are available?
===========================================
We're just relying on the underlying infrastructure here, nothing fancy.

Default is highestQuality (since we're only performing this operation once and caching
the result) but you can specify any of the following algorithms on the URL:

* highestQuality
* highQuality
* mediumQuality
* highestPerformance
* highPerformance
* mediumPerformance
* nearest
* bilinear
* bicubic
* bessel
* blackman
* hamming
* hanning
* hermite
* lanczos
mitchell
quadratic