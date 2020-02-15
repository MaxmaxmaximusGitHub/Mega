export class Node


	@isNode = yes


	@createClass: (ChildClass)->
		ChildClass.isNode = yes
		return ChildClass


	constructor: (parent)->
		Node.create(@, parent)
		return


	@create: (self, parent = null)->
		self.isNode = yes
		self.parent = parent
		return

