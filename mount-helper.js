#!/usr/local/bin/node

const http = require('http');
const fs = require('fs');
const { execSync } = require('child_process');
const url = require('url');

const server = http.createServer(function (req, res) {

    if (req.method === "GET" && req.url && req.url.startsWith("/mount-bind")) {
        const query = url.parse(req.url, true).query;
        const source = decodeURIComponent(query.source).replace(`'`, ``);
        const mountPoint = decodeURIComponent(query.mountPoint).replace(`'`, ``);
        const command = `mount --bind '${source}' '${mountPoint}'`;

        let stdout;
        try {
            stdout = execSync(command)
            res.writeHead(200, {'Content-Type': 'application/json'});
            res.end(JSON.stringify({stdout: stdout ? stdout.toString() : null}));
        } catch (stderr) {
            res.writeHead(400, {'Content-Type': 'application/json'});
            res.end(JSON.stringify({
                stdout: stdout ? stdout.toString() : null, 
                stderr: stderr.toString(),
                message: `Operation failed. Command was: ${command}`,
            }));
        }
    } else {
        res.writeHead(404);
        res.end();
    }

}).listen(80);