#!/usr/bin/env node
/* eslint-disable no-console */
'use strict';

/**
 * harness-adapter-compliance.js
 *
 * Thin wrapper around `harness-audit.js` that scopes the audit to a specific
 * harness adapter directory (`.codex/` or `.gemini/`) and re-emits a normalised
 * envelope with `overall_score`, `max_score`, `score_pct`, `categories[]`,
 * `failed_checks[]`, and `top_actions[]` for use by the `multi-ai-sync` skill
 * as a pre-sync compliance gate.
 *
 * Usage:
 *   node .claude/scripts/harness-adapter-compliance.js --target <codex|gemini> --format <text|json>
 *
 * Exits non-zero on:
 *   - unknown / missing args
 *   - target directory not present in repo root
 *   - underlying harness-audit.js failure
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const SUPPORTED_TARGETS = ['codex', 'gemini'];
const DEFAULT_FORMAT = 'text';
const DEFAULT_THRESHOLD_PCT = 60;

function printHelp() {
  console.log([
    'Usage: node .claude/scripts/harness-adapter-compliance.js [options]',
    '',
    'Score the compliance of a harness adapter directory using harness-audit.js.',
    '',
    'Options:',
    '  --target <codex|gemini>   Adapter directory to audit (required)',
    '  --format <text|json>      Output format (default: text)',
    '  --threshold <pct>         Pass threshold as percentage of max_score (default: 60)',
    '  -h, --help                Show this help',
  ].join('\n'));
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const parsed = {
    target: null,
    format: DEFAULT_FORMAT,
    threshold: DEFAULT_THRESHOLD_PCT,
    help: false,
  };

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];

    if (arg === '-h' || arg === '--help') {
      parsed.help = true;
      continue;
    }

    if (arg === '--target') {
      parsed.target = (args[i + 1] || '').toLowerCase();
      i += 1;
      continue;
    }

    if (arg.startsWith('--target=')) {
      parsed.target = arg.slice('--target='.length).toLowerCase();
      continue;
    }

    if (arg === '--format') {
      parsed.format = (args[i + 1] || '').toLowerCase();
      i += 1;
      continue;
    }

    if (arg.startsWith('--format=')) {
      parsed.format = arg.slice('--format='.length).toLowerCase();
      continue;
    }

    if (arg === '--threshold') {
      parsed.threshold = Number(args[i + 1]);
      i += 1;
      continue;
    }

    if (arg.startsWith('--threshold=')) {
      parsed.threshold = Number(arg.slice('--threshold='.length));
      continue;
    }

    throw new Error('Unknown argument: ' + arg);
  }

  if (parsed.help) {
    return parsed;
  }

  if (!parsed.target) {
    throw new Error('--target is required (codex|gemini)');
  }

  if (!SUPPORTED_TARGETS.includes(parsed.target)) {
    throw new Error('--target must be one of: ' + SUPPORTED_TARGETS.join(', '));
  }

  if (!['text', 'json'].includes(parsed.format)) {
    throw new Error('--format must be text or json');
  }

  if (!Number.isFinite(parsed.threshold) || parsed.threshold < 0 || parsed.threshold > 100) {
    throw new Error('--threshold must be a number between 0 and 100');
  }

  return parsed;
}

function repoRoot() {
  return path.resolve(__dirname, '..', '..');
}

function runHarnessAudit(targetDir) {
  const auditScript = path.join(__dirname, 'harness-audit.js');
  if (!fs.existsSync(auditScript)) {
    throw new Error('harness-audit.js not found at ' + auditScript);
  }

  if (!fs.existsSync(targetDir)) {
    throw new Error('Target adapter directory not found: ' + targetDir);
  }

  const raw = execFileSync(
    process.execPath,
    [auditScript, '--root', targetDir, '--format', 'json'],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }
  );

  return JSON.parse(raw);
}

function buildPayload(target, audit, thresholdPct) {
  const categories = Object.keys(audit.categories || {}).map(function (name) {
    const cat = audit.categories[name];
    return {
      name: name,
      score: cat.score,
      earned: cat.earned,
      max: cat.max,
    };
  });

  const failedChecks = (audit.checks || []).filter(function (c) { return !c.pass; });
  const scorePct = audit.max_score > 0
    ? Math.round((audit.overall_score / audit.max_score) * 1000) / 10
    : 0;

  return {
    schema_version: 'harness-adapter-compliance.v1',
    target: target,
    target_root: audit.root_dir,
    rubric_version: audit.rubric_version,
    overall_score: audit.overall_score,
    max_score: audit.max_score,
    score_pct: scorePct,
    threshold_pct: thresholdPct,
    passes_threshold: scorePct >= thresholdPct,
    categories: categories,
    failed_checks: failedChecks.map(function (c) {
      return {
        category: c.category,
        check_name: c.id,
        file_path: c.path,
        reason: c.description,
        points: c.points,
      };
    }),
    top_actions: (audit.top_actions || []).slice(0, 3),
  };
}

function renderText(payload) {
  const lines = [
    'Harness Adapter Compliance — target=' + payload.target,
    'Score: ' + payload.overall_score + '/' + payload.max_score + ' (' + payload.score_pct + '%)',
    'Threshold: ' + payload.threshold_pct + '% — ' + (payload.passes_threshold ? 'PASS' : 'FAIL'),
    '',
    'Categories:',
  ];

  payload.categories.forEach(function (c) {
    lines.push('  - ' + c.name + ': ' + c.earned + '/' + c.max);
  });

  if (payload.top_actions.length > 0) {
    lines.push('', 'Top actions:');
    payload.top_actions.forEach(function (a, i) {
      lines.push('  ' + (i + 1) + ') [' + a.category + '] ' + a.action + ' (' + a.path + ')');
    });
  }

  return lines.join('\n');
}

function main() {
  let parsed;
  try {
    parsed = parseArgs(process.argv);
  } catch (error) {
    console.error('Error: ' + error.message);
    process.exit(2);
  }

  if (parsed.help) {
    printHelp();
    return;
  }

  const targetDir = path.join(repoRoot(), '.' + parsed.target);

  let audit;
  try {
    audit = runHarnessAudit(targetDir);
  } catch (error) {
    console.error('Error: ' + error.message);
    process.exit(1);
  }

  const payload = buildPayload(parsed.target, audit, parsed.threshold);

  if (parsed.format === 'json') {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    console.log(renderText(payload));
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  parseArgs: parseArgs,
  buildPayload: buildPayload,
  SUPPORTED_TARGETS: SUPPORTED_TARGETS,
};
