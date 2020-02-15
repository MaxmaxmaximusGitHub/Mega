import {Reactive} from "./Reactive"


# TODO .firstRun it was ".first" prop
export class Binding


	constructor: (@target, targetExp, @scope, scopeExp)->
		@isStoped = off
		@targetExp = new Exp(targetExp)
		@scopeExp = new Exp(scopeExp)

		@toTargetComp = null
		@toScoptComp = null
		Reactive.run(@toTarget)
		Reactive.run(@toScope)
		return


	stop: ->
		if @isStoped then return
		@isStoped = yes
		@toTargetComp.stop()
		@toScoptComp.stop()
		return


	toTarget: (@toTargetComp)=>
		scopeVal = @getScopeValue()
		if @toTargetComp.firstRun and scopeVal is undefined then return
		@setTargetValue(scopeVal)
		return


	toScope: (@toScoptComp)=>
		targetVal = @getTargetValue()
		if @toScoptComp.firstRun and targetVal is undefined then return
		@setScopeValue(targetVal)
		# reactivity back propagation
		@setTargetValue(@getScopeValue())
		return


	getScopeValue: ->
		return @scopeExp.get(@scope)


	setScopeValue: (value)->
		return @scopeExp.set(@scope, value)


	getTargetValue: ->
		return @targetExp.get(@target)


	setTargetValue: (value)->
		return @targetExp.set(@target, value)

