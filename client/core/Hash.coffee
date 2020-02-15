export class Hash

	constructor: (obj)->
		if obj
			for own key, value of obj
				@[key] = obj
		return


Object.setPrototypeOf(Hash.prototype, null)
delete Hash.prototype.constructor


