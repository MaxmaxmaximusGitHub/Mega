import {Mongo} from "meteor/mongo"
import {DB} from './DB'


export class Collection extends Mongo.Collection


	Collection.schema = (schema)->
		q = new Collection()
		q.activate(schema)
		return


	activate: ->

		return



global.Collection = Collection


