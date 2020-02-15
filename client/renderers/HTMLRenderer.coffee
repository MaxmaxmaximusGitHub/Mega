export class HTMLRenderer


	constructor: (@node)->
		return


	render: ->
		return @constructor.render(@node)


	@render: (node)->
		if node.isElement
			return @renderElement(node)

		if node.isText
			return @renderText(node)

		if node.isDirective
			return @renderDirective(node)

		if node.isComment
			return @renderComment(node)

		console.error 'unknonwn render node type', node
		return


	@renderElement: (node)->
		html = "<#{node.tag}>"
		for child in node.children
			html += @render(child)
		html += "</#{node.tag}>"
		return html


	@renderText: (node)->
		return @escapeText(node.value)


	@renderDirective: (node)->
		html = ''

#		html += "<!--#{@escapeComment(node.name)}-->"

		for node in node.content
			html += @render(node)
		return html


	@renderComment: (node)->
		return "<!--#{@escapeComment(node.value)}-->"


	@escapeText: (string)->
		return string
			.replace(/&/img, '&amp;')
			.replace(/</img, '&lt;')
			.replace(/>/img, '&gt;')


	@escapeComment: (string)->
		return string
			.replace(/-->/img, '--&gt;')


