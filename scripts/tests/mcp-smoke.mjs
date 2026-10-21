import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';

const [command, ...args] = process.argv.slice(2);
assert.ok(command, 'Usage: node scripts/tests/mcp-smoke.mjs <server> [args...]');

const child = spawn(command, args, { stdio: ['pipe', 'pipe', 'inherit'] });
let finished = false;
const timeout = setTimeout(() => {
  console.error('MCP initialization/tools listing timed out after 30 seconds');
  process.exitCode = 1;
  child.kill();
}, 30_000);

function fail(error) {
  console.error(error);
  process.exitCode = 1;
  clearTimeout(timeout);
  child.kill();
}

function send(message) {
  child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', ...message })}\n`);
}

child.on('error', fail);
child.stdin.on('error', fail);
child.on('exit', (code, signal) => {
  clearTimeout(timeout);
  if (!finished) {
    console.error(`MCP server exited before tools/list completed: ${code ?? signal}`);
    process.exitCode = 1;
  }
});

createInterface({ input: child.stdout }).on('line', (line) => {
  try {
    const message = JSON.parse(line);
    assert.equal(message.jsonrpc, '2.0');
    assert.equal(message.error, undefined, JSON.stringify(message.error));
    if (message.id === 1) {
      assert.equal(typeof message.result.protocolVersion, 'string');
      assert.equal(typeof message.result.serverInfo.name, 'string');
      send({ method: 'notifications/initialized' });
      send({ id: 2, method: 'tools/list', params: {} });
    } else if (message.id === 2) {
      const tools = message.result.tools;
      assert.ok(Array.isArray(tools) && tools.length > 0, 'Server must advertise tools');
      for (const tool of tools) {
        assert.equal(typeof tool.name, 'string');
        assert.equal(tool.inputSchema.type, 'object');
      }
      finished = true;
      clearTimeout(timeout);
      console.log(`${command}: ${tools.length} tools, MCP handshake passed`);
      child.kill();
    }
  } catch (error) {
    fail(error);
  }
});

send({
  id: 1,
  method: 'initialize',
  params: {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'dotfiles-smoke-test', version: '1.0.0' },
  },
});
