import {Reactive} from "./Reactive"


export class Calculation


	constructor: (@handler)->
		@dependencies = []
		@destroyed = off
		@needsCalc = off
		@first = yes
		@run()
		@first = off
		return


	destroy: ->
		if @destroyed then return
		@destroyed = yes
		@needsCalc = off
		dependencies = @dependencies
		@handler = null
		@dependencies = null

		for dependency in dependencies
			dependency.removeCalculation(@)

		Reactive.canselRequestCalc(@)
		return


	addDependency: (dependency)->
		unless dependency in @dependencies
			@dependencies.push(dependency)
		return


	run: ->
		if @destroyed then return
		prevCalc = Reactive.calculation
		Reactive.calculation = @
		@handler.call(@, @)
		@needsCalc = off
		Reactive.calculation = prevCalc
		return


	invalidate: ->
		if @destroyed then return
		if @needsCalc then return
		@needsCalc = yes
		Reactive.requestCalc(@)
		return


	calc: ->
		if @destroyed then return
		if @needsCalc then @run()
		return



########################################################
# fake calculation for isomorphic server rendering
########################################################
export class FakeCalculation

	constructor: ->
		@first = yes
		return

	destroy: ->
		return


