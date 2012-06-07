<!--- image.cfc
	copyright 2012, Joseph R. Jones
	https://github.com/jrjones/jrj-image-server
	
	I am a simple component representing an image to be resized
--->

<cfcomponent>
	<cfproperty name="width" type="numeric" hint="The width in pixels of the original image" />
	<cfproperty name="height" type="numeric" hint="The height in pixels of the original image" />
	<cfproperty name="format" type="string" hint="The format of the current image (examples: png,jpg,gif)" />
	<cfproperty name="filepath" type="string" hint="The filename of the current image (must exist in images folder)" />
	<cfproperty name="colorDepth" type="string" hint="The color depth in bits of the current image (24,16,8 bit images supported)" />
	<cfproperty name="outputHeight" type="numeric" hint="The height in pixels at which the resized image will be output" />
	<cfproperty name="outputWidth" type="numeric" hint="The width in pixels at which the resized image will be output" />
	<cfproperty name="outputColorDepth" type="string" hint="The color depth at which the resized image will be output (32,24,16,8 bit images supported)" />
	<cfproperty name="resizeType" type="string" hint="The type of resize performed (examples: bicubic, nearest, quadratic, etc. default is highestQuality)" />
	<cfproperty name="validFormats" type="string" hint="A list of image formats supported" />
	<cfproperty name="validColorDepths" type="string" hint="A list of color depths supported" />
	<cfproperty name="validResizeTypes" type="string" hint="A list of supported image resize types" />
	<cfproperty name="gfxDir" type="string" hint="The current graphics directory" />
	<cfproperty name="tmpDir" type="string" hint="The current temp directory for files beyond a specified size (smaller images will be performed in ram)" />
	<cfproperty name="Transparency" type="string" hint="OPAQUE/TRANSPARENT" />
	
	<!--- START pseudo-constructor --->	
	<cfset this.validFormats = "png,png8,png24,jpg,jpeg,gif" />
	<!--- "png,png8,png24,jpg,jpeg,gif" StructKeyList(application.enum.imageFormats)--->
	
	<cfset this.validColorDepths = "24,16,8" />
	<!---"24,16,8" StructKeyList(application.enum.imageColorDepths) --->
	
	<cfset this.validResizeTypes = "highestQuality,lanczos,highquality,mitchell,mediumPerformance,quadratic,mediumquality,hamming,hanning,hermite,highPerformance,blackman,bessel,highestPerformance,nearest,bicubic,bilinear" /> 
	<!---"highestQuality,lanczos,highquality,mitchell,mediumPerformance, 
			quadratic,mediumquality,hamming,hanning,hermite,highPerformance,blackman,
			bessel,highestPerformance,nearest,bicubic,bilinear" StructKeyList(application.enum.imageResizeAlgos) 
	--->
	
	<cfset this.defaultResizeType = "highestQuality" />	
	<cfset this.gfxDir = GetDirectoryFromPath(GetTemplatePath()) />
	<cfset this.tmpDir = "#this.gfxDir#/tmp" />
	<!--- END pseudo-constructor --->

	<cffunction name="init" returntype="void" access="public">
		<cfargument name="filename" type="string" required="true" />
		
		<!--- validate filetype --->
		<cfset this.fileExtLoc = ListLen(arguments.filename,".") />
		<cfset this.fileExt = ListGetAt(arguments.filename,this.fileExtLoc,".") />
		<cfif ListContainsNoCase(this.validFormats,this.fileExt)>
			<cfset this.format = this.fileext>
		<cfelse>
			<cfthrow message="Only image filetypes (#this.validFormats#) are allowed." />
		</cfif>
		
		<!--- file must exist in this directory - we do not want to enable people to traverse the file system --->
		<cfif fileExists("#GetDirectoryFromPath(GetTemplatePath())#/#arguments.filename#")>
			<cfset this.filepath = "#GetDirectoryFromPath(GetTemplatePath())#/#arguments.filename#">
		<cfelse>
			<cfthrow message="Image file #GetDirectoryFromPath(GetTemplatePath())#/#arguments.filename# does not exist in gfx root." />
		</cfif>
		
		<!--- populate this image object based on information from the file --->
		<cfset ImageInfoStruct = this.GetImageInfoFromFile(this.filepath) />
		<cfset this.populateImageInfo(ImageInfoStruct) />
		
		<cfreturn>
	</cffunction>
	
	<cffunction name="Resize" returntype="any" access="public">
		<cfargument name="filename" type="string" required="true" />
		<cfargument name="height" type="numeric" required="false" default="0" />
		<cfargument name="width" type="numeric" required="false" default="0" />
		<cfargument name="format" type="string" required="false" default="" />
		<cfargument name="colorDepth" type="string" required="false" default="" />
		<cfargument name="resizeType" type="string" required="false" default="#application.enums.imageResizeAlgos.highestquality#" />

		<!--- validate format --->
		<cfif arguments.format NEQ "" AND not StructKeyExists(application.enum.imageFormats, arguments.format)>
			<cfthrow message="invalid format specified - #arguments.format#. Allowed formats are #this.validFormats#" />
		</cfif>
		
		<!--- validate colorDepth --->
		<cfif arguments.colorDepth NEQ "" AND not StructKeyExists(application.enum.ColorDepths, arguments.colorDepth)>
			<cfthrow message="Invalid color depth - #arguments.colorDepth#. Allowed colordepth values are #this.validColorDepths#" />
		</cfif>
		
		<!--- validate resizeType --->
		<cfif NOT ListContainsNoCase(this.validResizeTypes,arguments.resizeType)>
			<cfthrow message="Invalid resizeType specified (#arguments.resizeType#) - valid values are #this.validResizeTypes#" />
		</cfif>
		
		<!--- validate height --->
		<cfif arguments.height GT this.height>
			<!--- We're not going to resize up-- only down. So return the same image --->
			<cfset this.outputHeight = this.height />		
		<cfelseif arguments.height IS 0 AND arguments.width IS 0>
			<!--- no change in height or width - return the same image --->
			<cfset this.outputHeight = this.height />
		<cfelseif arguments.height IS 0 AND arguments.width NEQ 0>
			<!--- width was passed with no height - use outputHeight of empty string to constrain aspect ratio --->
			<cfset this.outputHeight = "" />
		<cfelseif arguments.height NEQ 0 AND arguments.width IS 0>
			<!--- height is passed with zero width - use outputWidth of empty string to constrain aspect ratio --->
			<cfset this.outputHeight = arguments.height />
			<cfset this.outputWidth = "" />
		<cfelse>
			<!--- non-zero height and width were passed - we will not constrain aspect ratio. --->
			<cfset this.outputHeight = arguments.height />
		</cfif>

		<!--- validate width --->		
		<cfif arguments.width GT this.width>
			<!--- we are not going to resize up, only down. So return the same image --->
			<cfset this.outputWidth = this.width />
		<cfelseif arguments.width IS 0 AND arguments.height IS 0>
			<!--- no change in width or height - return the same image --->
			<cfset this.outputWidth = this.width>
		<cfelseif arguments.width IS 0 AND arguments.height NEQ 0>
			<!--- height was passed with no width - use outputWidth of empty string to constrain aspect ratio --->
			<cfset this.outputWidth = "" />
		<cfelseif arguments.width NEQ 0 AND arguments.height IS 0>
			<!--- with is passed with zero height - use outputHeight of empty string to constrain aspect ratio --->	
			<cfset this.outputWidth = arguments.width />
			<cfset this.outputHeight = "" />
		<cfelse>
			<!--- with is passed with height - we are not constraining aspect ratio --->
			<cfset this.outputWidth = arguments.width />
		</cfif>
		
		<!--- validate filename --->
		<cfif not fileExists("#this.gfxDir#/#arguments.filename#")>
			<cfthrow message="File #this.gfxdir#/#filename# does not exist. Cannot resize a non-existent image" />
		</cfif>
		

		<!--- read in the original image --->		
		<cfset this.img = ImageRead("#this.gfxdir#/#arguments.filename#")>

		<!--- validate file is image --->
		<cfif NOT isImage(this.img)>
			<cfthrow message="#arguments.filename# does not appear to be a valid image file.">
		</cfif>

		
		<cfif this.outputWidth IS this.width AND this.outputHeight IS this.height>
			<!--- no size change - output the original image --->
			<cfreturn img>
		<cfelseif this.outputWidth IS "" AND this.outputHeight IS "">
			<!--- no size change - output the original image --->
			<cfreturn img>
		<cfelse>
			<!--- Perform Image Resize --->
			<cfif arguments.height IS 0><cfset arguments.height = ""></cfif>
			<cfif arguments.width IS 0><cfset arguments.width = ""></cfif>
			<cfscript>
				this.sourceImage = this.filepath;
				this.finfo = getFileInfo(this.sourceImage);
				this.iinfo = imageInfo(this.img);
				// need to consider if there is a more efficient method than duplicating the image-- doesn't look like this takes up much memory, but worth testing different alternatives.
				this.newImage = duplicate(this.img);
				// this is the actual scaling operation
				imageScaleToFit(this.newImage, arguments.height, arguments.width, arguments.resizeType);
				// write to tmp file with unique filename
				tmpfilename = CreateUUID() & "_" & getFileFromPath(this.sourceImage);
				imageWrite(this.newImage,"#this.tmpDir#/#tmpFileName#",1);
				// doing this imageRead is necessary, otherwise the newImage.source attribute doesn't refresh and we output the old image insead of the new one.
				this.newImage = ImageRead("#this.tmpDir#/#tmpFileName#");
			</cfscript>
			<!--- output the resized image --->
			<cfreturn this.newImage>
		</cfif>
	</cffunction>
	
	<cffunction name="GetImageInfoFromFile" access="package" returntype="struct">
		<cfargument name="filename" type="string" hint="The file you want to inspect" />
		<cfscript>
			this.testImg = imageRead(arguments.filename);
			imgInfo = imageInfo(this.testImg);
			fileInfo = GetFileInfo(imgInfo.source);
			myInfo = StructNew();
			myInfo.height = imgInfo.height;
			myInfo.width = imgInfo.width;
			myInfo.colorDepth = imgInfo.ColorModel.pixel_size;
			myInfo.transparency = imgInfo.ColorModel.transparency;
			myInfo.filePath = imgInfo.source;						
			return myInfo;
		</cfscript>
	</cffunction>
	
	<cffunction name="populateImageInfo" access="package" returntype="void">
		<cfargument name="ImageInfoStruct" type="struct" required="true">
		<cfscript>
			s = arguments.ImageInfoStruct;
			this.height = s.height;
			this.width = s.width;
			this.colorDepth = s.colorDepth;
			this.transparency = s.transparency;
			return;
		</cfscript> 
	</cffunction>
	
	<cffunction name="GetMimeType" access="public" returntype="string" hint="Returns the mime type expected for the specified filetype. If no filetype is passed, will specify mime type for this image object.">
		<cfargument name="filetype" required="false" default="#this.format#" hint="The filetype (jpg,png,gif, etc.) for which you wish to get the mime type... unsupported filetypes will throw an exception. If you do not pass a filetype we will default to the format of this image object.">
		<cfswitch expression="#arguments.filetype#">
			<cfcase value="gif">
				<cfreturn "image/gif">
			</cfcase>
			<cfcase value="png">
				<cfreturn "image/png">
			</cfcase>
			<cfcase value="jpg">
				<cfreturn "image/jpeg">
			</cfcase>
			<cfcase value="jpeg">
				<cfreturn "image/jpeg">
			</cfcase>
			<cfcase value="png8">
				<cfreturn "image/png">
			</cfcase>
			<cfcase value="png24">
				<cfreturn "image/png">
			</cfcase>
			<cfdefaultcase>
				<cfthrow message="Invalid filetype passed to GetMimeType - #arguments.filetype#" />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>
	
</cfcomponent>