var cors = require( 'cors' )
var io = require('socket.io');
var express = require( 'express' );
var compress = require('compression');
var port = (process.env.VCAP_APP_PORT || 9099);
var host = (process.env.VCAP_APP_HOST || '192.16.196.96');
var http = require('http');
var sys = require('sys');
var net = require('net');
var static = require('node-static');

var app = express( ), server = http.createServer(), socket = require('socket.io').listen(server);
var fs = require( 'fs' );
var MDB = require('monetdb')();
var MonetDBPool = require("monetdb-pool");

var sets = {
        bridge: { file : 'data/bgt_bridge_mbr.sql',sql: ''},
        bridgepilons: { file : 'data/bgt_bridgepilons_mbr.sql',sql: ''},
        buildings: { file : 'data/bgt_buildings_mbr.sql',sql: ''},
        groundpoints: { file : 'data/bgt_groundpoints_mbr.sql',sql: ''},
        kade: { file : 'data/bgt_kade_mbr.sql',sql: ''},
        lights: { file : 'data/bgt_lights_mbr.sql',sql: ''},
        road: { file : 'data/bgt_road_mbr.sql',sql: ''},
        scheiding: { file : 'data/bgt_scheiding_mbr.sql',sql: ''},
        steiger: { file : 'data/bgt_steiger_mbr.sql',sql: ''},
        terrain: { file : 'data/bgt_terrain_mbr.sql',sql: ''},
        water: { file : 'data/bgt_water_mbr.sql',sql: ''},
        treepoints: { file : 'data/bgt_treepoints_mbr.sql',sql: ''}
};
for( var s in sets ) {
        sets [ s ].sql = fs.readFileSync( sets [ s ].file ).toString( );
};

var options = {
	host     : 'localhost',
    port     : 55000,
    dbname   : 'bgt',
    user     : 'monetdb',
    password : 'monetdb',
    maxReconnects : 100,
    reconnectTimeout : 30000
};

//var client = new MDB(options);
//var p = client.connect();

var poolOptions = {
	nrConnections: 8
};

var dbOptions = {
	host     : 'localhost',
    port     : 55000,
    dbname   : 'bgt',
    user     : 'monetdb',
    password : 'monetdb',
    maxReconnects : 100,
    reconnectTimeout : 30000
};

var pool = new MonetDBPool(poolOptions, dbOptions);
pool.connect();

app.use(express.static('public'));
app.use( cors( ));
app.use(compress());
app.get( '/service/monetdb_3d', function( req, res ) {
                var north = req.query [ 'north' ];
                var south = req.query [ 'south' ];
                var west = req.query [ 'west' ];
                var east = req.query [ 'east' ];
                var set = req.query [ 'set' ] || 'terrain';
                //var client = require('monetdb')();

                /*
                var options = {
                    host     : 'localhost',
                    port     : 55000,
                    dbname   : 'bgt',
                    user     : 'monetdb',
                    password : 'monetdb',
                    maxReconnects : 100,
                    reconnectTimeout : 30000
                };
                */
                var querystring = sets [ set ].sql;
                                querystring = querystring
                                        .replace( /_west/g, west + '.0')
                                        .replace( /_east/g, east + '.0')
                                        .replace( /_south/g, south + '.0')
                                        .replace( /_north/g, north + '.0')
                                        .replace( /_zoom/g ,1)
                                        .replace( /_segmentlength/g,10);
                console.log('running: ',querystring);
                //var client = new MDB(options);
                //var p = client.connect();
                //p.then(function( err ) {
                //        if( err ) {
                //            res.send( 'Romulo could not connect to monetdb');
                //            client.disconnect();
                //        }
                var err;        
                        console.log('Set: ',set);
                        pool.query( querystring).then(function( result) {
                                if( err ) {
                                console.warn( err, querystring );
                                }
                                //console.log(querystring);
                                var resultstring = 'id;type;color;geom;';
                                //for (var key in result.data[0]){
                                //      resultstring += key + ';'
                                //}

                                resultstring += "\n";
                                if (result.data)
                                    result.data.forEach( function( row ) {
                                            for (var key in row){
                                            resultstring += row[key] + ';'
                                            }               
                                            resultstring += '\n';
                                            } );                            
                                res.set( "Content-Type", 'text/plain' );
                                res.send(resultstring);         
                                /*                              
                                                                res.set("Content-Type", 'text/javascript'); // i added this to avoid the "Resource interpreted as Script but tra                                     nsferred with MIME type text/html" message
                                                                res.send(JSON.stringify({data: result.rows}));
                                                                */                              
                                if (result.data)
                                    console.log( 'Sending results', result.data.length );

                        } ).catch(function(e){                          
                            console.warn('monetdb did a boo boo',e);   
                            });                                             
                //} );
} );                                                                            

app.listen( 8083, function( ) {                                 
      console.log( 'BGT X3D service listening on port 8083' );
} );
