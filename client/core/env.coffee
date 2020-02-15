import {Meteor} from 'meteor/meteor'

export env = new class Env

	constructor: ->
		@isClient = Meteor.isClient
		@isServer = Meteor.isServer

#		@emulateServer()
		return


	emulateServer: ->
		@isClient = off
		@isServer = yes
		return
