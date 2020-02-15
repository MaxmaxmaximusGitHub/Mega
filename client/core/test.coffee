import Benchmark from 'benchmark'

global.Benchmark = Benchmark
suite = new Benchmark.Suite()


suite.on 'start', ->
	console.log 'start testing...'
	return


suite.on 'complete', ->
	console.log 'done!'
	return


suite.on 'cycle', ({target})->
	if target.error
		console.error target.name + '\n\n', target.error
		return

	message = getResult(target)
	console.log message
	return


getResult = (benchmark)->
	perSec = formatValue(benchmark.hz)
	perFrame = formatValue(benchmark.hz / 60)
	opTime = (1 / benchmark.hz * 1000).toFixed(4)
	name = JSON.stringify(benchmark.name)
	return "#{name} #{opTime} ms | x #{perFrame} ops/frame | x #{perSec} ops/sec"


formatValue = (value)->
	return value.toFixed(0).split('').reverse().join('')
		.match(/.{1,3}/g).join(',')
		.split('').reverse().join('')


runned = off
testIsActive = yes


test = (name, handler)->
	unless testIsActive
		return handler()

	suite.add(name, handler)

	setTimeout =>
		unless runned
			runned = yes
			suite.run({async: yes})
		return
	return


test.active = ->
	testIsActive = yes
	return


export {test, suite}

