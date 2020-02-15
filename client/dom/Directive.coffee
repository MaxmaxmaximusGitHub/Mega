import {Node} from "./Node"


export class Directive extends Node


	@isDirective = yes


	@createClass: (ChildClass)->
		Node.createClass(ChildClass)
		ChildClass.isDirective = yes
		return ChildClass


	constructor: (parent)->
		super(parent)

		@isDirective = yes
		@content = []
		return


	@create: (self, parent)->
		Node.create(self, parent)

		self.isDirective = yes
		self.content = []
		return

