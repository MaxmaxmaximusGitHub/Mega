Package.describe({
	name: 'ui-compiler',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: ''
});


Package.registerBuildPlugin({
	name: 'compile-pug-templates',
	use: ['coffeescript'],
	sources: ['plugin/compileTemplates.coffee']
});


Package.onUse(function (api) {
	api.use('isobuild:compiler-plugin@1.0.0');
});

