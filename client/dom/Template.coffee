import {Directive} from "./Directive"


export class Template extends Directive


	constructor: (parent, attrs, childHandler)->
		super(parent)
		componentDirective = @parent
		name = componentDirective.name

		@element = ui.create("ui-#{name}", parent, attrs, childHandler)
		@content = [@element]
		return

