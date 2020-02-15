import {env} from './env'
import {test} from "./test"
import {Reactive} from "./Reactive"


REACTIVE_STORAGE = '#reactive'


export class Component

	@isComponent = yes
	@templates = null
	@depends = null

	# to make it optional to pass a parameter to the parent constructor
	currentNode = null


	@create: (node)->
		currentNode = node
		return new @(node)


	constructor: ->
		if env.isClient
			@[REACTIVE_STORAGE] = new Reactive({
				node: currentNode
			})
		else
			@node = currentNode
		return


	require: (compName, necessarily = yes)->
		node = @node.parent

		while node
			if node.isComponentDirective
				if node.name is compName
					return node.component

			node = node.parent

		if necessarily
			throw new Error(
				"Can't find parent \"#{compName}\" component for \"#{@node.name}\""
			)

		return null


	run: (handler)->
		return Reactive.run(handler)


	setInterval: (handler, time)->
		if env.isServer then return
		setInterval(handler, time)
		return


	setTimeout: (handler, time)->
		if env.isServer then return
		setTimeout(handler, time)
		return


	@register: (uiInstance = global.ui)->
		return uiInstance.add(@)


	@addTemplate: (type, template)->
		if arguments.length is 1
			template = arguments[0]
			type = 'default'

		unless @hasOwnProperty('templates')
			@templates = Object.create(null)
		@templates[type] = template

		@_updateDepends()
		return


	@getTemplate: (type = 'default')->
		unless @templates then return null
		return @templates[type]


	@_updateDepends: ->
		@depends = []
		for type, template of @templates
			for depend in template.depends
				if depend not in @depends
					@depends.push(depend)
		return



##################################################################
# if is client, add proxy to prototype, for reactivity
##################################################################
if env.isClient

	Object.defineProperty Component.prototype, REACTIVE_STORAGE,
		value   : null
		writable: yes


	Object.setPrototypeOf Component.prototype, new Proxy {},
		get: (tar, key, res)->
			return res[REACTIVE_STORAGE].get(key)

		set: (tar, key, val, res)->
			res[REACTIVE_STORAGE].set(key, val)
			return yes

