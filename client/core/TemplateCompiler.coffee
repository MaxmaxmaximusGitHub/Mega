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

		code = @compileObj(templateData)
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


	compileObj: (obj, withNewLine = yes)->
		lines = Object.keys(obj).map (key)=>
			return "#{key}: #{obj[key]}"

		if withNewLine
			lines = lines.map (line)=> "\t" + line
			code = lines.join(',\n\n')
			code = "{\n#{code}\n}"
		else
			code = lines.join(', ')
			code = "{#{code}}"

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
			when 'comment' then @compileComment(node, indentLevel)
			when 'text' then @compileText(node, indentLevel)
			when 'if' then @compileIf(node, indentLevel)
			else
				console.log 'unknown ast node type', node


	compileIf: (node, indentLevel = 1)->
		indent = @_indentation(indentLevel)

		variantsCodes = node.variants.map (variant)=>
			expCode = @compileGetter(variant.exp)
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
		codeAttrs = @compileAttrs(node.attrs)
		code = "new #{@UI}.dom.#{tag}(#{@PARENT}, #{codeAttrs}"

		if node.children.length
			childrenBlock = @compileBlock(node.children, indentLevel + 1)
			code += ", (parent) => #{childrenBlock}"

		code += ")"
		return code


	compileAttrs: (attrs)->
		attrsObj = {}

		if attrs.ids.length
			ids = attrs.ids.map (idExp)=>
				return @compileGetterOrValue(idExp)
			attrsObj.ids = @compileArr(ids)

		if attrs.classes.length
			classes = attrs.classes.map (classExp)=>
				return @compileGetterOrValue(classExp)
			attrsObj.classes = @compileArr(classes)

		if attrs.events.length
			events = attrs.events.map (event)=>
				return "{
					name: #{@string(event.name)},
					exp: #{@compileGetter(event.exp)}
				}"
			attrsObj.events = @compileArr(events)

		unless Object.keys(attrsObj).length
			return 'null'

		code = @compileObj(attrsObj, off)
		return code


	compileArr: (parts)->
		return "[#{parts.join(', ')}]"


	compileText: (node)->
		parts = node.parts.map (part)=>
			if part.type is 'text'
				return @string(part.value)
			else
				return @compileGetter(part.value)

		code = "new #{@UI}.Text(#{@PARENT}, [#{parts.join(', ')}])"
		return code


	compileComment: (node, indentLevel = 0)->
		commentText = @string(node.value)
		code = "new #{@UI}.Comment(#{@PARENT}, #{commentText})"
		return code


	SIMPLE_STRING_LITERAL_REG_EXP = /^\s*("|')(?:(?!\1).)*\1\s*$/


	compileGetterOrValue: (exp)->
		if SIMPLE_STRING_LITERAL_REG_EXP.test(exp)
			return exp

		return @compileGetter(exp)


	compileGetter: (exp)->
		return "() => (#{@SCOPE}.#{exp})"


	compileSetter: (exp)->
		return "(#{@VALUE}) => (#{@SCOPE}.#{exp} = #{@VALUE})"


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
				props  : parsedAttrs.props
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
		props = []
		events = []
		classes = []

		for attr in allAttrs
			{name, val} = attr

			if match = name.match(@EVENT_REGEX)
				name = match[1] or match[2]
				events.push({name, exp: val})

			else if match = name.match(@STYLE_REGEX)
				name = "style.#{camelCase(match[1])}"
				props.push({path: name, exp: val})

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
					classes.push("#{val} && '#{match[1]}'")

			else
				props.push({path: name, exp: val})

		return {ids, classes, props, events}


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



