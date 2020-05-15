#!/usr/local/bin/node

const http = require('http');
const fs = require('fs');
const { execSync } = require('child_process');
const url = require('url');

function runCommand(command) {
    let stdout;
    try {
        stdout = execSync(command)
        return { success: true, stdout: stdout ? stdout.toString() : null, stderr: null, message: null };
    } catch (stderr) {
        return {
            success: false,
            stdout: stdout ? stdout.toString() : null,
            stderr: stderr.toString(),
            message: `Operation failed. Command was: ${command}`,
        }
    }
}

const server = http.createServer(function (req, res) {
    if (req.url.startsWith("/mount-bind?")) {
        const query = url.parse(req.url, true).query;

        if (!query.mountPoint || !query.source || !query.mountPoint.length || !query.source.length) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end();
            return;
        }

        const source = decodeURIComponent(query.source).replace(`'`, ``);
        const mountPoint = decodeURIComponent(query.mountPoint).replace(`'`, ``);
        const command = `mount --bind '${source}' '${mountPoint}'`;
        const result = runCommand(command);

        res.writeHead(result.success === true ? 200 : 500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));

        return;
    }

    if (req.url.startsWith("/unmount?") || req.url.startsWith("/umount?")) {
        const query = url.parse(req.url, true).query;

        if (!query.mountPoint || !query.mountPoint.length) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end();
            return;
        }

        const mountPoint = decodeURIComponent(query.mountPoint).replace(`'`, ``);
        const command = `umount '${mountPoint}'`;
        const result = runCommand(command);

        res.writeHead(result.success === true ? 200 : 500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));

        return;
    }

    if (req.url.startsWith("/unmount-recursive?") || req.url.startsWith("/umount-recursive?")) {
        const query = url.parse(req.url, true).query;

        if (!query.baseDirectory || !query.baseDirectory.length) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end();
            return;
        }

        const baseDirectory = decodeURIComponent(query.baseDirectory).replace(`'`, ``);
        const findMntCommand = `findmnt --kernel -n --list | grep -e '^${baseDirectory}' | sed 's/ \\/.*//' | sed 's/[ \\t]*$//g'`;
        const findMntResult = runCommand(findMntCommand);

        if (!findMntResult.success) {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(findMntResult));
            return;
        }

        const mountPoints = findMntResult.stdout.split('\n');

        const result = {
            success: true,
            stdout: findMntResult.stdout,
            stderr: findMntResult.stderr,
            message: findMntResult.message
        };

        for (const mp of mountPoints) {
            if (!mp || !mp.length) {
                continue;
            }

            const umountCommand = `umount '${mp.replace(`'`, ``)}'`;
            const umountResult = runCommand(umountCommand);

            if (umountResult.stdout && umountResult.stdout.length) {
                result.stdout += `\n${umountResult.stdout}`;
            }

            if (umountResult.stderr && umountResult.stderr.length) {
                result.stderr += `\n${umountResult.stderr}`;
            }
            
            if (umountResult.message && umountResult.message.length) {
                result.message += `\n${umountResult.message}`;
            }

            if (!umountResult.success) {
                result.success = false;
            }
        }

        res.writeHead(result.success === true ? 200 : 500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));

        return;
    }

    if (req.url.startsWith("/find-mounts?")) {
        const query = url.parse(req.url, true).query;

        if (!query.baseDirectory || !query.baseDirectory.length) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end();
            return;
        }

        const baseDirectory = decodeURIComponent(query.baseDirectory).replace(`'`, ``);
        const findMntCommand = `findmnt --kernel -n --list | grep -e '^${baseDirectory}' | sed 's/ \\/.*//' | sed 's/[ \\t]*$//g'`;
        const findMntResult = runCommand(findMntCommand);

        res.writeHead(findMntResult.success === true ? 200 : 500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(findMntResult));
    }

    res.writeHead(404);
    res.end();
    return;

}).listen(81);