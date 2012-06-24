<!--- 
	resize.cfm
	copyright 2012, Joseph R. Jones, Licensed under MIT license.
	
	I accept requests for resized images by parsing the query string
	to figure the file name and height (h) and width (w) values, 
	and plopping them into a imgParams struct that I can use to 
	call image.cfc's resize method and respond with the image
--->
<cfset lstPathItems = replace(cgi.path_info,"/",",","all")>
<cfset imgParams = structNew()>

<cfloop list="#lstPathItems#" index="i">
	<cfset LenMinus = val(len(i) - 1)>
	<cfif left(i,1) IS "w" AND NOT i CONTAINS "."> <!--- path includes a width attribute --->
		<cfset imgParams.width = val(right(i,LenMinus))>
	<cfelseif left(i,1) IS "h" AND NOT i CONTAINS "."> <!--- path includes a height attribute --->
		<cfset imgParams.height = val(right(i,LenMinus))>
	<cfelseif left(i,1) IS "r" AND NOT i CONTAINS "."> <!--- path includes a resize type --->
		<cfset imgParams.resizeType = right(i,lenMinus)>
	<cfelseif i CONTAINS "."> <!--- path includes something that looks like a filename --->
		<cfset imgParams.filename = i>
	<cfelse>
		<!--- do nothing, as this chunk of the path doesn't look like an attribute we know about --->
	</cfif>
</cfloop>
	
<cfparam name="imgParams.height" default="0">
<cfparam name="imgParams.width" default="0">
<cfparam name="imgParams.filename" default="fileNotFound.png">
<cfparam name="imgParams.resizeType" default="highestQuality">

<!--- the image specified in the filename parameter --->
<cfset img = new image(#imgParams.filename#)>

<cfswitch expression="#ListGetAt(imgParams.filename,2,".")#">
	<cfcase value="jpg">
		<cfset imgParams.format = "jpg">
	</cfcase>
	<cfcase value="jpeg">
		<cfset imgParams.format = "jpg">
	</cfcase>
	<cfcase value="png">
		<cfset imgParams.format = "png">
	</cfcase>
	<cfcase value="gif">
		<cfset imgParams.format = "png">
	</cfcase>
	<cfdefaultcase>
		<cfset imgParams.format = "png">
	</cfdefaultcase>
</cfswitch>

<!--- a resized version of the image --->
<cfset resizedImg = img.resize(filename=imgParams.filename, height=imgParams.height, width=imgParams.width, resizeType=imgParams.resizeType, format=imgParams.format)>

<!--- delete old files to keep the directory from getting too big. --->
<cfset img.cleanUpTempDirectory()>

<!--- output the resized image in response to the request. --->
<cffile action="readbinary" file="#resizedImg.source#" variable="resizedFileContent" />
<cfcontent type="#img.GetMimeType(img.format)#" variable="#resizedFileContent#" >
