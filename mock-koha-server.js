const http = require('http');
const { URLSearchParams } = require('url');

const TEST_USERNAME = 'teststudent';
const TEST_PASSWORD = 'test1234';

const server = http.createServer((req, res) => {
  if (req.method !== 'POST' || req.url !== '/api/v1/auth/password') {
    res.writeHead(404);
    res.end();
    return;
  }

  let body = '';
  req.on('data', chunk => (body += chunk));
  req.on('end', () => {
    const params = new URLSearchParams(body);
    const userid = params.get('userid');
    const password = params.get('password');

    console.log(`Login attempt: userid=${userid}`);

    if (userid === TEST_USERNAME && password === TEST_PASSWORD) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ access_token: 'mock-token-123', patron_id: '1001' }));
    } else {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid credentials' }));
    }
  });
});

server.listen(8080, '0.0.0.0', () => {
  console.log('Mock Koha server running on port 8080');
});
