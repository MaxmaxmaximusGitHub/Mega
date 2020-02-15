export class Scope


	constructor: (@data = Object.create(null))->
		return  new Proxy @data,
			has           : @has
			get           : @get
			set           : @set
			deleteProperty: @deleteProperty

			ownKeys                 : (target, key)=> console.log 'ownKeys'
			getOwnPropertyDescriptor: (target, key)=> console.log 'getOwnPropertyDescriptor'
			hasOwn                  : (target, key)=> console.log 'hasOwn'
			enumerate               : (target, key)=> console.log 'enumerate'
			iterate                 : (target, key)=> console.log 'iterate'
			defineProperty          : (target, key, desc)=> console.log 'defineProperty'
			getPropertyNames        : (target)=> console.log 'getPropertyNames'
			getOwnPropertyNames     : (target)=> console.log 'getOwnPropertyNames'
			getOwnPropertyDescriptor: (target, key)=> console.log 'getOwnPropertyDescriptor'
			apply                   : (target, key)=> console.log 'apply'
			construct               : (target, key)=> console.log 'construct'


	has: (target, key)=>
		return key isnt 'arguments'

	get: (target, key)=>
		return target[key]

	set: (target, key, value)=>
		target[key] = value
		return yes

	deleteProperty: (target, key)=>
		delete target[key]
		return yes

