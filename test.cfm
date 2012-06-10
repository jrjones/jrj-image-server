<!---
	test.cfm
	Copyright 2012, Joseph R. Jones, Licensed under MIT license.
	
	I am just a quick visual test of the functionality. I call the image resizer a few times from within html via <img> tags
--->

<html>
	<head>
		<title>Test Image Handler</title>
		<style>
			.imageContainer
			{
				width: 700;
				height: 400;
				overflow: scroll;
				border: solid 1px black;
			}
		</style>
	</head>
	<body>
		<h1>Image Test</h1>
		<cfset lstImages = "bridge.jpg,logo.jpg,person.jpg">
		
		<cfloop list="#lstImages#" index="i">
			<cfset imgUrl = "./resized.cfm/w300/#i#">
			<h2>Resized</h2>
			<div class="imageContainer">
				<cfoutput>
					<a href="#imgUrl#">#imgUrl#</a><br />
					<img src="#imgUrl#">
				</cfoutput>
			</div>
		</cfloop>		
	</body>
</html>


