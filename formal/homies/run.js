#!/usr/bin/env node
/**
 * Homies formal-verification runner.
 *
 * Runs TLC (pinned tla2tools, see tools/fetch-tla2tools.sh) on every
 * configuration below and asserts the EXPECTED outcome per config:
 *   - pass: TLC exit 0 and "Model checking completed. No error"
 *   - a specific invariant violation: TLC must report exactly
 *     "Invariant <name> is violated" (any other failure — parse error,
 *     timeout, different invariant, deadlock — fails the run).
 *
 * Expected-fail configs are either findings against the baseline
 * (as-deployed) model or reachability probes proving non-vacuity.
 * Full TLC output is preserved under out/<config>.log.
 *
 * Usage: node formal/homies/run.js   (TLA_JAVA overrides the java binary)
 */
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const DIR = __dirname;
const OUT = path.join(DIR, 'out');
const JAR = path.join(DIR, 'tools', 'tla2tools.jar');
const JAVA = process.env.TLA_JAVA || 'java';
const TIMEOUT_MS = 25 * 60 * 1000;

// Optional CLI filter: `node run.js Baseline_Mutual Corrected_Full` runs a subset.
const only = process.argv.slice(2);

// expect: 'pass' | invariant name that must be reported violated
const RUNS = [
  { cfg: 'Baseline_Mutual', expect: 'MutualHomies' },
  { cfg: 'Baseline_QuiescentMutual_NoCrash', expect: 'QuiescentMutualHomies' },
  { cfg: 'Baseline_QuiescentMutual_Crash', expect: 'QuiescentMutualHomies' },
  { cfg: 'Baseline_GhostAcceptance', expect: 'NoGhostAcceptance' },
  { cfg: 'Baseline_DuplicateHomies', expect: 'NoDuplicateHomies' },
  { cfg: 'Baseline_DuplicateRequests', expect: 'NoDuplicateRequests' },
  { cfg: 'Baseline_Resurrect', expect: 'NoResurrectedConnection' },
  { cfg: 'Baseline_RequestSymmetry', expect: 'QuiescentRequestSymmetry' },
  { cfg: 'Baseline_Holds', expect: 'pass' },
  { cfg: 'Corrected_Tx', expect: 'pass' },
  { cfg: 'Corrected_Tx_Resurrect', expect: 'NoResurrectedConnection' },
  { cfg: 'Corrected_Full', expect: 'pass' },
  { cfg: 'Corrected_Full_3Riders', expect: 'pass' },
  { cfg: 'Reach_Connected', expect: 'ReachNeverConnected' },
  { cfg: 'Reach_Reconnect', expect: 'ReachNoReconnect' },
];

if (!fs.existsSync(JAR)) {
  console.log(`Missing ${JAR} — run formal/homies/tools/fetch-tla2tools.sh first.`);
  process.exit(2);
}
fs.mkdirSync(OUT, { recursive: true });

function runTlc(cfg) {
  const metadir = path.join(OUT, `states-${cfg}`);
  const args = [
    '-XX:+UseParallelGC',
    '-cp',
    JAR,
    'tlc2.TLC',
    '-config',
    `${cfg}.cfg`,
    '-metadir',
    metadir,
    '-deadlock', // operation budgets make terminal states expected
    '-workers',
    'auto',
    'Homies.tla',
  ];
  let stdout = '';
  let status = 0;
  try {
    stdout = execFileSync(JAVA, args, {
      cwd: DIR,
      timeout: TIMEOUT_MS,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (err) {
    if (err.status === undefined && err.stdout === undefined) throw err;
    stdout = `${err.stdout || ''}${err.stderr || ''}`;
    status = err.status === null ? -1 : err.status; // null => killed (timeout)
  }
  fs.rmSync(metadir, { recursive: true, force: true });
  return { stdout, status };
}

function stats(output) {
  const m = output.match(/(\d+) states generated, (\d+) distinct states found/);
  const d = output.match(/The depth of the complete state graph search is (\d+)/);
  if (!m) return 'state counts unavailable';
  return `${m[1]} generated, ${m[2]} distinct${d ? `, depth ${d[1]}` : ''}`;
}

let failed = 0;
const selected = only.length > 0 ? RUNS.filter((r) => only.includes(r.cfg)) : RUNS;
for (const { cfg, expect } of selected) {
  const { stdout, status } = runTlc(cfg);
  fs.writeFileSync(path.join(OUT, `${cfg}.log`), stdout);
  const completedClean = status === 0 && stdout.includes('Model checking completed. No error');
  const violated = (name) => stdout.includes(`Invariant ${name} is violated`);

  let ok;
  let detail;
  if (expect === 'pass') {
    ok = completedClean;
    detail = ok ? stats(stdout) : `exit ${status}; see out/${cfg}.log`;
  } else {
    // Must be the *specific* expected invariant — nothing else counts.
    ok = violated(expect) && !stdout.includes('Parsing or semantic analysis failed');
    detail = ok
      ? `expected violation of ${expect} reproduced (trace in out/${cfg}.log)`
      : `expected "Invariant ${expect} is violated", got exit ${status}; see out/${cfg}.log`;
  }
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${cfg.padEnd(34)} ${detail}`);
  if (!ok) failed += 1;
}

if (failed > 0) {
  console.log(`\n${failed} run(s) did not match their expected outcome.`);
  process.exit(1);
}
console.log('\nAll runs matched their expected outcomes.');
