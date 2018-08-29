const redis = require('redis');
const express = require('express');
const http = require('http');

let db = null;
const app = express();

const checkRedis = () => {
    if(db === null) {
        db = redis.createClient({
            host: process.env.REDIS_HOST || 'redis',
            port: process.env.REDIS_PORT,
            db: process.env.REDIS_DB,
        });
        db.on('end', () => {
            db = null;
        });
    }
};
const getKeys = (keys) => new Promise((resolve, reject) => {
    db.keys(keys, (err, res) => {
        if(err) {
            reject(err);
        } else {
            resolve(res);
        }
    });
});
const getValue = (key) => new Promise((resolve, reject) => {
    db.get(key, (err, res) => {
        if(err) {
            reject(err);
        } else {
            resolve(res);
        }
    });
});
const getValues = (keys) => new Promise((resolve, reject) => {
    db.mget(keys, (err, res) => {
        if(err) {
            reject(err);
        } else {
            resolve(res);
        }
    });
});

console.log(__dirname + '/static');
app.use(express.static(__dirname + '/static'));

app.get('/hosts', async (req, res) => {
    checkRedis();
    const keys = await getKeys('fingo:*');
    const values = await getValues(keys);
    res.json({
        hosts: values.map(v => JSON.parse(v)).map((v, i) => ({ ...v, mac: keys[i].substr(6) }))
    });
});

app.get('/values/:mac([0-9A-Fa-f:]{17})/?', (req, res) => {
    const mac = req.params.mac;
    const pastTime = req.query.pastTime || (24 * 60 * 60);
    const fill = req.query.fill || '0';
    const time = Number(req.query.time || '1');

    if(fill !== 'previous' && fill !== 'null' && fill !== '0') {
        return res.status(400).json({ message: 'Expected fill to be either previous, null or 0' });
    }

    let goodTime;
    switch(time) {
    case 1: goodTime = '1m'; break;
    case 2: goodTime = '5m'; break;
    case 3: goodTime = '10m'; break;
    case 4: goodTime = '30m'; break;
    default: goodTime = '1m';
    }

    const query = Object.entries({
        db: process.env.INFLUXDB_DB,
        q: `SELECT round(mean("state")) AS "state" FROM "week_rp"."activity" WHERE time > NOW() - ${pastTime}s AND "mac"='${mac}' GROUP BY time(${goodTime}) FILL(${fill})`
    }).map((pair) => `${pair[0]}=${encodeURIComponent(pair[1])}`).join('&');

    http.get(`http://${process.env.INFLUXDB_HOST}:${process.env.INFLUXDB_PORT}/query?${query}`, (r) => {
        r.setEncoding('utf-8');
        let rawData = '';
        r.on('data', (chunk) => { rawData += chunk });
        r.on('end', () => {
            const data = JSON.parse(rawData);
            if(res.statusCode !== 200) {
                res.status(500).json(data);
            } else {
                res.json(data);
            }
        });
    });
});

app.listen(3000, () => console.log('Listening at port 3000'));
