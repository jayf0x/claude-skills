#!/usr/bin/env node
import { readdirSync, existsSync, readFileSync } from 'node:fs';
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

const manifests = plugins.map((plugin) => {
  const manifestPath = join(PLUGINS_DIR, plugin, '.claude-plugin', 'plugin.json');
  if (!existsSync(manifestPath)) {
    console.error(`precommit: ${plugin} is missing .claude-plugin/plugin.json`);
    process.exit(1);
  }
  const { name, description } = JSON.parse(readFileSync(manifestPath, 'utf8'));
  return { plugin, name, description };
});

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

const escapeCell = (text) => text.replace(/\|/g, '\\|').replace(/\n/g, ' ');

const pluginsTable = [
  '| Plugin | Description | Install | Uninstall |',
  '| --- | --- | --- | --- |',
  ...manifests.map(
    ({ plugin, name, description }) =>
      `| [${name}](./plugins/${plugin}/README.md) | ${escapeCell(description)} | \`./plugins/${plugin}/install.sh\` | \`./plugins/${plugin}/uninstall.sh\` |`,
  ),
].join('\n');

const changed = taglifyFile(README, {
  INSTALL: installLines,
  UNINSTALL: uninstallLines,
  PLUGINS: pluginsTable,
});

if (changed) {
  console.log(`precommit: updated ${README}`);
}
