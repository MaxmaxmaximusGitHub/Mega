Plugin.registerCompiler
	extensions: ['pug']
, => new TemplatesCompiler()



class TemplatesCompiler


	processFilesForTarget: (files)->
		for file in files
			if @isExcluded(file) then continue
			@processFile(file)
		return


	processFile: (file)->
		content = file.getContentsAsBuffer().toString()

		file.addJavaScript
			data: "module.exports = #{JSON.stringify(content)}"
		return


	isExcluded: (file)=>
		path = file.getPathInPackage()
		parentDirs = path.split(Plugin.path.sep)
		return 'node_modules' in parentDirs




