Package.describe({
	name: 'db',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md'
});


// Package.registerBuildPlugin({
// 	name: 'compileGraphQL',
// 	use: ['ecmascript','coffeescript'],
// 	sources: [
// 		'plugin/plugin.coffee'
// 	],
// 	npmDependencies: {
// 		'graphql-tag': '2.10.1'
// 	}
// });


Package.onUse(function (api) {
	api.versionsFrom('1.8.3');
	api.use('ecmascript');
	api.use('coffeescript');
	api.use('isobuild:compiler-plugin@1.0.0');
	api.use('matb33:collection-hooks');
	api.addFiles('Collection.coffee');
	api.addFiles('DB.coffee');
	api.mainModule('exports.coffee');
});


