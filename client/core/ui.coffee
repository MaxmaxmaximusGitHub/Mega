import {ComponentDirective} from "../dom/ComponentDirective"
import {paramCase, pascalCase} from 'change-case'
import {Template} from "../dom/Template"
import {Element} from '../dom/Element'
import {Comment} from "../dom/Comment"
import {Component} from "./Component"
import {Reactive} from "./Reactive"
import {Text} from "../dom/Text"
import {If} from "../dom/If"
import {Hash} from "./Hash"


export class UI


	constructor: ->
		@Component = Component
		@Template = Template
		@Reactive = Reactive
		@Comment = Comment
		@Text = Text
		@Hash = Hash
		@If = If

		@dom = new Hash()
		@add(Template)
		return


	create: (Class, args...)->
		Class = @add(Class)
		return new Class(args...)


	add: (Class)->
		if typeof Class is 'string'
			return @addElement(Class)

		if Class.isComponent
			return @addComponent(Class)

		if Class.isDirective
			return @addDirective(Class)

		throw new Error(
			"Unknown DOM class \"#{Class.name}\",
			you must extends it from \"Node\""
		)
		return


	addDirective: (Class)->
		@dom[pascalCase(Class.name)] = Class
		return Class


	addElement: (tag)->
		tag = pascalCase(tag)
		if @dom[tag] then return @dom[tag]
		return @dom[tag] = @_createElementClass(tag)


	addComponent: (Class)->
		compName = pascalCase(Class.name)
		@dom[compName] = @_createComponentDirective(Class)
		# create dom elements by component depends
		@_addComponentDependens(Class)
		return @dom[compName]


	run: (handler)->
		return Reactive.run(handler)


	_createElementClass: (Class)->
		tag = paramCase(Class)
		jsonTag = JSON.stringify(tag)
		return eval("""Element.createClass(class #{Class} {
			constructor (parent, attrs, childHandler) {
				Element.create(this, #{jsonTag}, parent, attrs, childHandler);
			}
		})""")



	_addComponentDependens: (Class)->
		if Class.depends
			for depend in Class.depends
				@add(depend)
		return


	_createComponentDirective: (ComponentClass)->
		if ComponentClass.prototype not instanceof Component
			throw new Error("#{ComponentClass.name} must extends ui.Component")

		currentUI = @
		compName = pascalCase(ComponentClass.name)

		return eval("""ComponentDirective.createClass(
			class #{compName}ComponentDirective {
				constructor (parent, attrs, childHandler) {
					ComponentDirective.create(
						this, currentUI, ComponentClass, parent, attrs, childHandler
					)
				}
			}
		)
		""")



global['ui'] = new UI
export default ui



