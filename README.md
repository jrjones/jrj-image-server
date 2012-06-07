jrj-image-server
================

A simple image server that handles dynamic resizing of images for use as a cache origin server

What it does
================
This is a very basic image server, implemented in ColdFusion, which acts as an origin server for a cache. It allows you to quickly and easily resize images based on requests and let the result be cached.

The image resizing is slow-- this is NOT intended to be run on a front-end web server. The idea is to use as the origin server for a cache-- like, for example, Amazon CloudFront http://aws.amazon.com/cloudfront/  

You just bake in an image tag with a source of http://myimagecache.domain.com/resized.cfm/w300/h400/filename.jpg where filename.jpg is the name of an image file in the root, and wXXX and hXXX "directory" names control the height and width.

How to use it
================
Still working on some basic documentation, but it's pretty simple stuff. The only files you need are resized.cfm and image.cfc, the rest are just there for testing purposes. 

