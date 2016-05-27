var MDB = require('monetdb')();

var options = {
    host     : 'localhost', 
    port     : 55001, 
    dbname   : 'demo', 
    user     : 'monetdb', 
    password : 'monetdb'
};

var express = require("express");
var app = express();
var port = 3700;
 
var conn = new MDB(options);
conn.connect();

app.get("/", function(req, res){
    conn.query('SELECT * FROM tables').then(function(result) {
        res.send(result.data);
    });

    res.send("It works!");
});
 
var io = require('socket.io').listen(app.listen(port));
console.log("Listening on port " + port);

conn.close();
