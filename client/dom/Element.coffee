import {Node} from "./Node"
import {Hash} from "../core/Hash"


export class Element

	@createClass: (ChildClass)->
		Node.createClass(ChildClass)
		ChildClass.isElement = yes
		return ChildClass


	@create: (self, tag, parent, attrs, childHandler)->
		Node.create(self, parent)

		self.isElement = yes
		self.attrs = attrs
		self.tag = tag

		if childHandler
			self.children = childHandler(self)
		else
			self.children = []
		return


