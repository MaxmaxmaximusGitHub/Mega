import parser from 'pug-parser'
import lexer from 'pug-lexer'
import {camelCase, paramCase, pascalCase} from 'change-case'


export class TemplateCompiler

	PARENT: 'parent'
	SCOPE : 'scope'
	VALUE : 'val'
	TAB   : '\t'
	UI    : 'ui'


	@create: (code)->
		templateCode = @compile(code)
		return eval("(#{templateCode})")


	@compile: (code)->
		compiler = new TemplateCompiler()
		return compiler.compile(code)


	compile: (code)->
		block = @parse(code)

		templateData =
			depends: JSON.stringify(@getTags(block))
			render : @compileRendererFunc(block, 2)

		code = @objToString(templateData)
		return code


	getTags: (block, tags = [])->
		for node in block

			switch node.type
				when 'element'
					tag = pascalCase(node.tag)
					if tag not in tags then tags.push(tag)
					@getTags(node.children, tags)

				when 'if'
					for variant in node.variants
						@getTags(variant.content, tags)
					if node.else
						@getTags(node.else, tags)

		return tags


	objToString: (obj)->
		lines = Object.keys(obj).map (key)=>
			return "\t#{key}: #{obj[key]}"
		code = lines.join(',\n\n')
		code = "{\n#{code}\n}"
		return code


	compileRendererFunc: (block, indentLevel = 1)->
		compiledBlock = @compileBlock(block, indentLevel)
		code = "(#{@PARENT}, #{@SCOPE}, #{@UI}) => #{compiledBlock}"
		return code


	compileBlock: (block, indentLevel = 0)->
		nodesCodes = block.map (node)=>
			return @compileNode(node, indentLevel)

		indent = @_indentation(indentLevel)

		if indent
			nodesCodes = nodesCodes.map (nodeCode)=>
				return indent + nodeCode

		code = nodesCodes.join(',\n')
		code = "[\n#{code}\n#{indent.slice(1)}]"
		return code



	_indentation: (indentLevel)->
		indent = ''
		if indentLevel
			for i in [0...indentLevel]
				indent += @TAB
		return indent


	compileNode: (node, indentLevel = 0)->
		return switch node.type
			when 'element' then @compileElement(node, indentLevel)
			when 'text' then @compileText(node, indentLevel)
			when 'comment' then @compileComment(node, indentLevel)
			when 'if' then @compileIf(node, indentLevel)
			else
				console.log 'unknown ast node type', node


	compileIf: (node, indentLevel = 1)->
		indent = @_indentation(indentLevel)

		variantsCodes = node.variants.map (variant)=>
			expCode = @compileExpGetter(variant.exp)
			contentCode = @compileBlock(variant.content, indentLevel + 1)
			variantCode = "[#{expCode}, (#{@PARENT}) => #{contentCode}]"
			return variantCode

		variantsCode = variantsCodes.join(",\n#{indent}")
		variantsCode = "[#{variantsCode}]"

		code = "new #{@UI}.If(#{variantsCode}"

		if node.else
			elseBlockCode = @compileBlock(node.else, indentLevel + 1)
			code += ", (#{@PARENT}) => #{elseBlockCode}"

		code += ')'
		return code


	compileElement: (node, indentLevel = 0)->
		tag = pascalCase(node.tag)
		code = "new #{@UI}.dom.#{tag}(#{@PARENT}, null"

		if node.children.length
			childrenBlock = @compileBlock(node.children, indentLevel + 1)
			code += ", (parent) => #{childrenBlock}"

		code += ")"
		return code


	compileText: (node, indentLevel = 0)->
		parts = node.parts.map (part)=>
			if part.type is 'text'
				return @string(part.value)
			else
				return @compileExpGetter(part.value)

		code = "new #{@UI}.Text(#{@PARENT}, [#{parts.join(', ')}])"
		return code


	compileComment: (node, indentLevel = 0)->
		commentText = @string(node.value)
		code = "new #{@UI}.Comment(#{@PARENT}, #{commentText})"
		return code


	compileExpGetter: (code)->
		return "() => (#{@SCOPE}.#{code})"


	compileExpSetter: (code)->
		return "(#{@VALUE}) => (#{@SCOPE}.#{code} = #{@VALUE})"


	parse: (code)->
		pugAst = parser(lexer(code))
		block = @parseAstNode(pugAst)
		return block


	parseAstNode: (node)->
		return switch node.type
			when 'Block' then @parseBlock(node)
			when 'Tag' then @parseTag(node)
			when 'Text' then @parseText(node)
			when 'Comment' then @parseComment(node)
			when 'Conditional' then @parseConditional(node)
			when 'Each' then @parseEach(node)
			when 'Code' then @parseCode(node)
			else
				console.log 'unknown ast node type', node


	parseBlock: (blockAstNode)->
		nodes = []

		if blockAstNode.nodes.length
			for childAstNode in blockAstNode.nodes
				nodes.push @parseAstNode(childAstNode)
			nodes = @_concatTextNodes(nodes)

		return nodes


	_concatTextNodes: (nodes)->
		normalizedNodes = []
		lastNode = null

		for node in nodes
			if lastNode
				if lastNode.type is 'text' and node.type is 'text'
					lastNode.parts.push(node.parts...)
					continue

			normalizedNodes.push(node)
			lastNode = node

		for node in normalizedNodes
			if node.type is 'text'
				@_normalizeTextParts(node)

		return normalizedNodes


	_normalizeTextParts: (node)->
		lastPart = null
		normalizedParts = []

		for part in node.parts
			if lastPart
				if lastPart.type is 'text' and part.type is 'text'
					lastPart.value += part.value
					continue
			normalizedParts.push(part)
			lastPart = part

		node.parts = normalizedParts
		return


	parseTag: (tagAstNode)->
		parsedAttrs = @_parseAttrs(tagAstNode.attrs)

		return {
			type: 'element'
			tag : paramCase(tagAstNode.name)

			attrs:
				ids    : parsedAttrs.ids
				attrs  : parsedAttrs.attrs
				events : parsedAttrs.events
				classes: parsedAttrs.classes

			children: @parseBlock(tagAstNode.block)
		}


	CLASS_REGEX: /^\.(.+)/
	STYLE_REGEX: /^\[(.+)]/
	ID_REGEX   : /^#(.+)/
	EVENT_REGEX: /^\((.+)\)|^@(.+)/


	_parseAttrs: (allAttrs)->
		ids = []
		attrs = []
		events = []
		classes = []

		for attr in allAttrs
			{name, val} = attr

			if match = name.match(@EVENT_REGEX)
				name = match[1] or match[2]
				events.push({name, exp: val})

			else if match = name.match(@STYLE_REGEX)
				name = "style.#{camelCase(match[1])}"
				attrs.push({name, value: val})

			else if name is 'id'
				ids.push(val)

			else if match = name.match(@ID_REGEX)
				if val is true
					ids.push("'#{match[1]}'")
				else
					ids.push("#{val} ? '#{match[1]}' : ''")

			else if name is 'class'
				classes.push(val)

			else if match = name.match(@CLASS_REGEX)
				if val is true
					classes.push("'#{match[1]}'")
				else
					classes.push("#{val} ? '#{match[1]}' : ''")

			else
				attrs.push({name, value: val})

		return {ids, classes, attrs, events}


	parseEach: (eachAstNode)->
		return {
			type   : 'for'
			exp    : eachAstNode.obj
			val    : eachAstNode.val
			key    : eachAstNode.key
			content: @parseAstNode(eachAstNode.block)
		}


	parseConditional: (conditionalAstNode)->
		variants = []

		cond = conditionalAstNode
		while cond and cond.type is 'Conditional'
			variant = @_getVariant(cond)
			variants.push(variant)
			cond = cond.alternate

		if cond
			alternate = @parseAstNode(cond)
		else
			alternate = null

		return {
			type    : 'if'
			variants: variants
			else    : alternate
		}


	_getVariant: (conditionalAstNode)->
		return {
			exp    : conditionalAstNode.test
			content: @parseBlock(conditionalAstNode.consequent)
		}


	parseText: (textAstNode)->
		return {
			type : 'text'
			parts: [{type: 'text', value: textAstNode.val}]
		}

	parseCode: (codeAstNode)->
		return {
			type : 'text'
			parts: [{type: 'exp', value: codeAstNode.val}]
		}


	parseComment: (commentAstNode)->
		return {
			type : 'comment'
			value: commentAstNode.val
		}


	string: (value)->
		return JSON.stringify(value)



