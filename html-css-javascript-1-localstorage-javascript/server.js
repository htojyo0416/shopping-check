const http = require("http");
const fs = require("fs");
const path = require("path");

const root = __dirname;
const os = require("os");

const port = 4173;

function getLocalAddresses() {
  return Object.values(os.networkInterfaces())
    .flat()
    .filter((address) => address && address.family === "IPv4" && !address.internal)
    .map((address) => address.address);
}

const server = http.createServer((req, res) => {
  const requested = req.url === "/" ? "index.html" : decodeURIComponent(req.url.slice(1));
  const file = path.join(root, requested);

  if (!file.startsWith(root)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(file, (error, data) => {
    if (error) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }

    res.writeHead(200, {
      "content-type": file.endsWith(".html") ? "text/html; charset=utf-8" : "application/octet-stream"
    });
    res.end(data);
  });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`PC: http://127.0.0.1:${port}`);
  getLocalAddresses().forEach((address) => {
    console.log(`Phone: http://${address}:${port}`);
  });
});
