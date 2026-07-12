#!/usr/bin/env node
import { readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { taglifyFile } from 'taglify';

const PLUGINS_DIR = 'plugins';
const README = 'README.md';

const plugins = readdirSync(PLUGINS_DIR, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

for (const plugin of plugins) {
  const uninstallPath = join(PLUGINS_DIR, plugin, 'uninstall.sh');
  if (!existsSync(uninstallPath)) {
    console.error(`precommit: ${plugin} is missing uninstall.sh — every skill requires one`);
    process.exit(1);
  }
}

const installLines = [
  '```bash',
  'git clone https://github.com/jayf0x/claude-skills',
  'cd claude-skills',
  '',
  '# all at once',
  './install.sh',
  '',
  '# or one at a time',
  ...plugins.map((plugin) => `./plugins/${plugin}/install.sh`),
  '```',
].join('\n');

const uninstallLines = [
  '```bash',
  ...plugins.map((plugin) => `./plugins/${plugin}/uninstall.sh`),
  '```',
].join('\n');

const changed = taglifyFile(README, {
  INSTALL: installLines,
  UNINSTALL: uninstallLines,
});

if (changed) {
  console.log(`precommit: updated ${README}`);
}
