var MDB = require('monetdb')();

var options = {
    host     : 'localhost', 
    port     : 55001, 
    dbname   : 'demo', 
    user     : 'monetdb', 
    password : 'monetdb'
};

var conn = new MDB(options);
conn.connect();

conn.query('SELECT * FROM mytable').then(function(result) {
    console.log(result.data);
});
  
conn.close();
