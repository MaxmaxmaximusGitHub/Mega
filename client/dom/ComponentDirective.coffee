import {Component} from "../core/Component"
import {Directive} from "./Directive"
import {Scope} from "../core/Scope"
import {Hash} from "../core/Hash"


export class ComponentDirective


	@createClass: (ChildClass)->
		Directive.createClass(ChildClass)
		ChildClass.isComponentDirective = yes
		return ChildClass


	@create: (self, ui, ComponentClass, parent, attrs, childHandler)->
		Directive.create(self, parent)
		self.isComponentDirective = yes

		self.ui = ui
		self.attrs = attrs
		self.name = ComponentClass.name

		if childHandler
			self.children = childHandler(self)
		else
			self.children = []

		# create controller
		self.component = ComponentClass.create(self)

		# if hasnt template, just show children as content
		unless template = ComponentClass.getTemplate()
			self.content = self.children
			return

		# render template
		self.content = template.render(self, self.component, self.ui)
		return

