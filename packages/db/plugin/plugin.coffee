graphqlParser = Npm.require('graphql-tag')


Plugin.registerCompiler
	extensions: ['graphql']
	filenames : []
, => new GraphQLCompiler()



class GraphQLCompiler


	processFilesForTarget: (files)->
		for file in files then @processFile(file)
		return


	processFile: (file)->
		if @needExcluded(file) then return
		schemaCode = file.getContentsAsString()
		schema = graphqlParser(schemaCode)
#
#		file.addJavaScript(
#			data: ";console.log(DB);"
#		)
		return


	needExcluded: (file)->
		path = file.getPathInPackage()
		dirs = path.split(Plugin.path.sep)
		return 'node_modules' in dirs


