import { writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Create a simple CJS wrapper
const cjsWrapper = `'use strict';

const { SubflagNodeProvider, SubflagApiError } = require('./index.js');

module.exports = {
  SubflagNodeProvider,
  SubflagApiError,
};
`;

writeFileSync(resolve(__dirname, '../dist/index.cjs'), cjsWrapper, 'utf-8');
console.log('✓ Created CommonJS wrapper');
