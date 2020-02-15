import {Reactive} from "./Reactive"
import {Hash} from "./Hash"


export class Dependency


	constructor: ->
		@calculations = []
		@data = new Hash()
		return


	depend: ->
		unless calculation = Reactive.calculation then return
		calculation.addDependency(@)
		unless calculation in @calculations
			@calculations.push(calculation)
		return


	removeCalculation: (calculation)->
		index = @calculations.indexOf(calculation)
		if index is -1 then return
		@calculations.splice(index, 1)
		return


	change: ->
		calculations = @calculations
		@calculations = []
		for calculation in calculations
			calculation.invalidate()
		return

