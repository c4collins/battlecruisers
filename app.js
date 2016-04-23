var express = require('express'),
    routes = require('./routes'),
    api = require('./routes/api'),
    bodyParser = require('body-parser'),
    http = require('http'),
    path = require('path');

var app = module.exports = express();

// All environments
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.set('port', process.env.PORT || 3000);
app.set('views', __dirname + '/dist/html');
app.set('view engine', 'jade');

var env = process.env.NODE_ENV || 'development';
// development only
if (env === 'development') {
    
}

// production only
if (env === 'production') {
  // TODO
}

// serve index and view partials
app.get('/', routes.index);
// app.get('/html/:name', routes.partials);
app.get('/partials/:name', routes.partials);

// JSON API
app.get('/api/name', api.name);

// redirect all others to the index (HTML5 history)
app.get('*', routes.index);


app.use(app.router);
app.use('/static', express.static(path.join(__dirname, 'dist/assets')));
// app.use('/html', express.static(path.join(__dirname, 'dist/html')));

http.createServer(app).listen(app.get('port'), function () {
  console.log('Express server listening on port ' + app.get('port'));
});
