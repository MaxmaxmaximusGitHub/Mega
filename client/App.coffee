import './core/ui'

import {HTMLRenderer} from "./renderers/HTMLRenderer"
import {TemplateCompiler} from "./core/TemplateCompiler"
import {Reactive} from "./core/Reactive"
import {Component} from "./core/Component"
import {Directive} from "./dom/Directive"
import {test} from "./core/test"


appTemplate = TemplateCompiler.create(require './App.pug')


class App extends Component

	@addTemplate(appTemplate)
	@register()

	constructor: ->
		super()
		@name = 'Ашот'

		@setInterval =>
			@name = Math.random().toFixed(3)
		, 1000
		return


app = new ui.dom.App()
document.body.innerHTML = HTMLRenderer.render(app)


#setInterval =>
#	document.body.innerHTML = HTMLRenderer.render(app)
#, 500
