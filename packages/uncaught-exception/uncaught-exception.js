(function () {
	var label = '$$ catcherInstalled $$'

	if (Meteor.isServer && Meteor.isDevelopment && !process[label]) {

		process.on('uncaughtException', (error) => {
			console.error(error)
		})

		process.on('unhandledRejection', (error) => {
			console.error(error)
		})

		process[label] = true
	}

})()
