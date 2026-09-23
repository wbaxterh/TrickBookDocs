#!/usr/bin/env node
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const dir = __dirname;
const out = path.join(dir, 'out');
const jar = path.join(dir, 'tools', 'tla2tools.jar');
const java = process.env.TLA_JAVA || 'java';
const runs = [
  { cfg: 'Model', expect: 'pass' },
  { cfg: 'ReachRequired', expect: 'RequiredPromptReachable' },
  { cfg: 'ReachOptional', expect: 'OptionalPromptReachable' },
  { cfg: 'ReachCore', expect: 'CoreActionReachable' },
  { cfg: 'ReachPremium', expect: 'PremiumActionReachable' },
];

if (!fs.existsSync(jar)) {
  console.error(
    `Missing ${jar}. Copy the pinned v1.7.4 jar from formal/homies/tools or run that fetch script.`,
  );
  process.exit(2);
}
fs.mkdirSync(out, { recursive: true });

let failures = 0;
for (const { cfg, expect } of runs) {
  const metadir = path.join(out, `states-${cfg}`);
  const args = [
    '-XX:+UseParallelGC',
    '-cp',
    jar,
    'tlc2.TLC',
    '-config',
    `${cfg}.cfg`,
    '-metadir',
    metadir,
    '-deadlock',
    '-workers',
    'auto',
    'RetentionLTV.tla',
  ];
  let output = '';
  let status = 0;
  try {
    output = execFileSync(java, args, {
      cwd: dir,
      timeout: 15 * 60 * 1000,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (error) {
    output = `${error.stdout || ''}${error.stderr || ''}`;
    status = error.status ?? -1;
  }
  fs.rmSync(metadir, { recursive: true, force: true });
  fs.writeFileSync(path.join(out, `${cfg}.log`), output);
  const clean = status === 0 && output.includes('Model checking completed. No error');
  const expected = output.includes(`Invariant ${expect} is violated`);
  const ok = expect === 'pass' ? clean : expected;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${cfg}: ${ok ? expect : `exit ${status}`}`);
  if (!ok) failures += 1;
}
if (failures) process.exit(1);
console.log('All retention/LTV model runs matched their expected outcomes.');
