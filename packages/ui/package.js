Package.describe({
	name: 'ui',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md'
});



Package.onUse(function (api) {
	api.versionsFrom('1.8.3');
	api.use('ecmascript');
	api.use('coffeescript');
	// api.mainModule('ui.client.coffee', 'client');
	// api.mainModule('ui.server.coffee', 'server');
});



Npm.depends({
	'jsdom': '16.0.0'
});
