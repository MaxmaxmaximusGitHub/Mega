import {Calculation, FakeCalculation} from "./Calculation"
import {Dependency} from "./Dependency"
import {env} from "./env"
import asap from 'asap'


export class Reactive

	@Dependency = Dependency
	@Calculation = Calculation
	@FAKE_CALCULATION = new FakeCalculation()

	@calculation = null
	@flushRequested = off
	@calculationsToRequestCalc = []

	@reactiveByTargetMap = new WeakMap()
	@createdReactivesSet = new WeakSet()
	@reactiveClasses = new Map()

	DEP_PREFIX = '@'
	VAL_PREFIX = '#'


	constructor: (@storage = {})->
		return


	@run: (handler)->
		if env.isServer
			calc = @FAKE_CALCULATION
			handler.call(calc, calc)
			return calc

		return new Calculation(handler)


	@requestCalc: (calculation)->
		if calculation not in @calculationsToRequestCalc
			@calculationsToRequestCalc.push(calculation)
		unless @flushRequested
			asap => @calc()
		return


	@canselRequestCalc: (calculation)->
		index = @calculationsToRequestCalc.indexOf(calculation)
		if index is -1 then return
		@calculationsToRequestCalc.splice(index, 1)
		return


	@calc: ->
		unless @calculationsToRequestCalc.length then return
		calculationsToRequestCalc = @calculationsToRequestCalc
		@calculationsToRequestCalc = []
		for calculation in calculationsToRequestCalc
			calculation.calc()
		return


	@create: (value)->
		# not reactivity primitive values
		if Object(value) isnt value
			return value

		# if it's already reactive, just return
		if @isReactive(value)
			return value

		# check reactives cache
		if reactive = @reactiveByTargetMap.get(value)
			return reactive

		# create reactive
		if ReactiveClass = @getReactiveClass(value)
			reactive = new ReactiveClass(value)
		else
			reactive = value
		#			throw new Error("Can not find Reactive Wrapper for #{value}")

		# cache reactive
		@createdReactivesSet.add(reactive)
		@reactiveByTargetMap.set(value, reactive)

		return reactive


	@wrapper: (TargetClass, ReactiveClass)->
		@reactiveClasses.set(TargetClass, ReactiveClass)
		return


	@isReactive: (value)->
		return @createdReactivesSet.has(value)


	@getReactiveClass: (target)->
		minPriority = Infinity
		PriorityReactiveClass = null

		for [TargetClass, ReactiveClass] from @reactiveClasses
			if target instanceof TargetClass
				if target.constructor is TargetClass
					return ReactiveClass
				priority = @_getExtendsPriority(target, TargetClass)

				if priority < minPriority
					minPriority = priority
					PriorityReactiveClass = ReactiveClass

		return PriorityReactiveClass


	@_getExtendsPriority: (target, TargetClass)->
		priority = 0
		while target
			if target.constructor is TargetClass then break
			target = Object.getPrototypeOf(target)
			priority++
		return priority


	get: (key)->
		value = @storage[key]
		return @depend(key, value)


	set: (key, value)->
		@storage[key] = value
		@check(key, value)
		return yes


	depend: (key, value)->
		if Reactive.calculation
			dependency = @[DEP_PREFIX + key] ?= new Dependency()
			dependency.data.oldValue = value
			dependency.depend()

		#			Tracker.onInvalidate =>
		#				unless @storage[key]?.hasDependents()
		#					delete @storage[key]

		return Reactive.create(value)


	check: (key, value)->
		dependency = @[DEP_PREFIX + key]
		unless dependency then return
		oldValue = dependency.data.oldValue

		if arguments.length < 2
			value = @storage[key]

		unless @equals(oldValue, value)
			dependency.data.oldValue = value
			dependency.change()
		return


	change: (key)->
		dependency = @[DEP_PREFIX + key]
		unless dependency then return
		dependency.data.oldValue = @storage[key]
		dependency.change()
		return


	equals: (val1, val2)->
		if val1 isnt val1 and val2 isnt val2
			return yes
		return val1 is val2



#####################################################
# add default reactive wrappers
#####################################################
Reactive.wrapper Object, (obj)->
	# dont wrap virtual dom nodes
	if obj.constructor.isNode then return obj

	reactive = new Reactive(obj)

	return new Proxy obj,
		get: (tar, key)->
			return reactive.get(key)

		set: (tar, key, value)->
			reactive.set(key, value)
			yes

