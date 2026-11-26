'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { greet } = require('..');

test('greet returns a greeting', () => {
  assert.strictEqual(greet('release owner'), 'Hello, release owner!');
});
