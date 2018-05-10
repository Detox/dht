/**
 * @package Detox DHT
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
fs				= require('fs')
gulp			= require('gulp')
run-sequence	= require('run-sequence')

require('build-gbu')('src/index.js', 'detox_dht', 'detox-dht.browser', ['debug', 'simple-sha1', 'simple-peer'], {
	task	: (task, dependencies, func) ->
		if dependencies && func
			dependencies	= []
		if task != 'build'
			gulp.task(task, dependencies, func)
		@
})
gulp
	.task('fix-bittorrent-dht', !->
		js	= fs.readFileSync("dist/detox-dht.browser.js", {encoding: 'utf8'})
		js	= js.replace("require('debug')('bittorrent-dht')", 'function () {}')
		fs.writeFileSync("dist/detox-dht.browser.js", js)
	)
	.task('build', !->
		run-sequence('clean', 'browserify', 'fix-bittorrent-dht', 'minify')
	)
