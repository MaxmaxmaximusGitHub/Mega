import {Directive} from "./Directive"
import {Reactive} from "../core/Reactive"


export class If


	constructor: (parent, @variants, @else = null)->
		Directive.create(@, parent)

		renderer = @getActualVariantRenderer()
		@content = renderer(@parent)
		return


	getActualVariantRenderer: ->
		for variant in @variants
			[exp, renderer] = variant
			if exp()
				return renderer
		return @else or -> []

