var gulp        = require('gulp'),
    gutil       = require('gulp-util'),
    stylus      = require('gulp-stylus'),
    inline      = require('rework-inline'),
    csso        = require('gulp-csso'),
    uglify      = require('gulp-uglify'),
    jade        = require('gulp-jade'),
    coffee      = require('gulp-coffee'),
    concat      = require('gulp-concat'),
    livereload  = require('gulp-livereload'), // Livereload plugin needed: https://chrome.google.com/webstore/detail/livereload/jnihajbhpnppcggbcgedagnkighmdlei
    tinylr      = require('tiny-lr'),
    express     = require('express'),
    app         = express(),
    marked      = require('marked'), // For :markdown filter in jade
    path        = require('path'),
    server      = tinylr(),
    es          = require('event-stream')
    // Routes
    routes      = require('./routes'),
    api         = require('./routes/api');


// --- Basic Tasks ---
gulp.task('css', function() {
  return gulp.src('src/assets/stylesheets/main.styl').
    pipe( stylus() ).
    // pipe( csso() ). // Turn off to de-compress
    // pipe( concat('main.css') ).
    pipe( gulp.dest('dist/assets/stylesheets/') ).
    pipe( livereload( server ));
});

gulp.task('js', function() {
  return es.merge(
        gulp.src('src/assets/scripts/*.coffee').
          pipe(coffee()),
        gulp.src('src/assets/scripts/*.js')).
    // pipe( uglify() ). // Turn off to de-uglify
    pipe( concat('all.min.js')).
    pipe( gulp.dest('dist/assets/scripts/')).
    pipe( livereload( server ));
});

gulp.task('templates', function() {
  return gulp.src(['src/templates/*.jade', 'src/templates/**/*.jade']).
    pipe(jade({
      pretty: true
    })).
    pipe(gulp.dest('dist/html')).
    pipe( livereload( server ));
});

gulp.task('express', function() {
  app.set('views', __dirname + '/src/templates');
  app.set('view engine', 'jade');
  app.use('/static', express.static(path.join(__dirname, 'dist/assets')));
  app.use(express.static(path.resolve('./dist/assets')));
  // serve index and view partials
  app.get('/', routes.index);
  app.get('/partials/:name', routes.partials);

  // JSON API
  app.get('/api/name', api.name);

  // redirect all others to the index (HTML5 history)
  app.get('*', routes.index);
  app.listen(3000);
  gutil.log('Listening on port: 3000');
});

gulp.task('watch', function () {
  server.listen(35729, function (err) {
    if (err) {
      return console.log(err);
    }

    gulp.watch('src/assets/stylesheets/*.styl',['css']);

    gulp.watch('src/assets/scripts/*.js',['js']);

    gulp.watch('src/assets/scripts/*.coffee',['js']);

    gulp.watch('src/*.jade',['templates']);

  });
});

// Default Task
gulp.task('default', ['js','css','templates','express','watch']);
