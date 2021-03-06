gulp = require 'gulp'
browserify = require 'browserify'
buffer = require 'vinyl-buffer'
concat = require 'gulp-concat'
babelify = require 'babelify'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
clean = require 'gulp-clean'
mocha = require 'gulp-mocha'
rm = require 'del'
source = require 'vinyl-source-stream'

logger = require('printit')
	date: false
	prefix: 'gulp'

BUILDDIR = 'build/'

watching = false
handleError = (err) ->
	logger.error err.toString
	if watching
		this.emit 'end'
	else
		process.exit 1


gulp.task 'default', ['b']
gulp.task 'b' , ['build-client', 'build-server']	# build
gulp.task 't' , ['test-client', 'test-server']		# test

gulp.task 'client-remove-dir', () ->
	return rm(BUILDDIR + 'client/')


gulp.task 'client-bundle-css', () ->
	return gulp.src('client/css/**/*')
	 .pipe(concat 'main.css')
	 .pipe(gulp.dest(BUILDDIR + 'client/css'))


gulp.task 'client-copy-static', () ->
	return gulp.src(['client/vendor/assets/**/*', 'client/app/assets/**/*'])
	 .pipe(gulp.dest(BUILDDIR + 'client/'))
	


gulp.task 'client-bundle-vendor', () ->
	return gulp.src('client/vendor/javascripts/*')
	 .pipe(concat 'vendor.js' )
	 .pipe(gulp.dest(BUILDDIR + 'client/javascripts'))


gulp.task 'build-client', ['client-remove-dir', 'client-copy-static', 'client-bundle-vendor', 'client-bundle-css'], () ->
	logger.options.prefix = 'gulp:build-client'
	logger.info "Start compilation..."

	browserify( entries: ['./client/app/initialize.coffee'], extensions: ['.coffee', '.jade'], debug: true )
	 .transform('jadeify')
	 .transform('coffeeify')
	 .bundle().on('error', gutil.log)
	 .pipe(source 'app.js' )
	 .pipe(gulp.dest(BUILDDIR + 'client/javascripts'))


gulp.task 'build-server', () ->
	logger.options.prefix = 'gulp:build-server'
	logger.info "Start compilation..."
	
	rm [BUILDDIR + 'server/', 'server.js']

	gulp.src('server/**/*.coffee')
	 .pipe(coffee( bare: true ).on('error', gutil.log))
	 .pipe(gulp.dest BUILDDIR + 'server/')
	
	gulp.src('server.coffee')
	 .pipe(coffee( bare: true ).on('error', gutil.log))
	 .pipe(gulp.dest BUILDDIR)

	gulp.src('package.json')
	 .pipe(gulp.dest BUILDDIR)



gulp.task 'test-client', () ->
	logger.options.prefix = 'gulp:test-client'
	logger.info "Start testing client..."
	
	# gulp.src ['tests/controllers/*.coffee'], read: false
	 # .pipe mocha reporter: 'spec'
	  # .on 'error', logger.error
	logger.error "No test implemented yet."

	logger.info "Testing client done."

gulp.task 'test-server', () ->
	logger.options.prefix = 'gulp:test-server'
	logger.info "Start testing server..."
	
	gulp.src ['tests/controllers/*.coffee'], read: false
	 .pipe(mocha( reporter: 'spec' ).on('error', gutil.log))

	logger.info "Testing server done."


gulp.task 'w', ['test-client', 'test-server'], () ->	# watch
	watching = true
	gulp.watch ['client/**/*.js', 'static/**/*'], ['test-client']
	gulp.watch ['server/**/*.coffee', 'server.coffee', 'tests/**/*'], ['test-server']
	
# gulp.task 'w' /* watch */, ['build-client', 'build-server'], () ->
	# gulp.watch ['client/**/*.js', 'static/**/*'], ['build-client']
	# gulp.watch ['server/**/*.coffee', 'server.coffee'], ['build-server']


gulp.task 'clean', () ->
	gulp.src BUILDDIR, force: true 
	 .pipe clean
