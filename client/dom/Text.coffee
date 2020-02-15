import {Reactive} from "../core/Reactive"
import {Node} from "./Node"
import {env} from '../core/env'


export class Text


	constructor: (parent, parts)->
		Node.create(@, parent)

		@isText = yes

		# optimization for server fast rendering
		if env.isServer
			value = ''
			for part in parts
				if typeof part is 'string'
					value += part
				else
					value += (part() ? '')
			@value = value
			return


		# optimization for one part and is text
		if parts.length is 1
			if typeof parts[0] is 'string'
				@value = parts[0]
				return


		# normal reactive client side rendering
		cache = []

		parts.forEach (exp, index)=>
			if typeof exp is 'string'
				cache.push(exp)
				return

			Reactive.run (comp)=>
				if comp.first
					cache.push(exp())
				else
					cache[index] = exp()
					@value = cache.join('')
				return
			return

		@value = cache.join('')
		return




