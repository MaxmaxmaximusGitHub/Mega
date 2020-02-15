import {Mongo} from "meteor/mongo"

`function DB() {}`


DB.prototype = new Proxy {},

	set: (target, name, value, receiver)->
		unless value instanceof Mongo.Collection
			return off
		name = name.toLowerCase()
		Reflect.set(target, name, value, receiver)
		return yes

	get: (target, name)->
		if typeof name is 'symbol'
			return target[name]
		name = name.toLowerCase()
		collection = Mongo.Collection.get(name)
		if collection then db[name] = collection
		return collection


db = new DB()

export {db as DB}
global.DB = db
