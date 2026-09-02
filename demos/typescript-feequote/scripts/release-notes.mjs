#!/usr/bin/env node
// Prints the commits between two tags grouped by conventional-commit type.
// The release-notes skill turns this output into the house format.
//
//   node scripts/release-notes.mjs v0.1.0 v0.2.0
import { execFileSync } from 'node:child_process';

const GROUPS = [
  { key: 'feature', title: 'feature', types: ['feat'] },
  { key: 'fix', title: 'fix', types: ['fix'] },
  { key: 'chore', title: 'chore', types: ['chore', 'build', 'ci', 'docs', 'refactor', 'style', 'test', 'perf'] },
];

const SUBJECT_PATTERN = /^(?<type>[a-z]+)(?:\([^)]*\))?!?:\s*(?<summary>.+)$/;

function usage() {
  console.error('Usage: node scripts/release-notes.mjs <from-tag> <to-tag>');
  process.exit(2);
}

function readSubjects(fromRef, toRef) {
  const output = execFileSync('git', ['log', '--no-merges', '--format=%s', `${fromRef}..${toRef}`], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'inherit'],
  });
  return output
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
}

function groupSubjects(subjects) {
  const grouped = new Map(GROUPS.map((group) => [group.key, []]));
  const other = [];
  for (const subject of subjects) {
    const match = SUBJECT_PATTERN.exec(subject);
    const group = match ? GROUPS.find((candidate) => candidate.types.includes(match.groups.type)) : undefined;
    if (match && group) {
      grouped.get(group.key).push(match.groups.summary);
    } else {
      other.push(subject);
    }
  }
  return { grouped, other };
}

function printGroup(title, entries) {
  console.log(`${title}:`);
  if (entries.length === 0) {
    console.log('  (none)');
  }
  for (const entry of entries) {
    console.log(`  - ${entry}`);
  }
}

const [fromRef, toRef] = process.argv.slice(2);
if (!fromRef || !toRef) {
  usage();
}

let subjects;
try {
  subjects = readSubjects(fromRef, toRef);
} catch (error) {
  console.error(`Could not read the git log for ${fromRef}..${toRef}: ${error.message}`);
  process.exit(1);
}

const { grouped, other } = groupSubjects(subjects);
console.log(`Commits ${fromRef}..${toRef} (${subjects.length} total)`);
for (const group of GROUPS) {
  printGroup(group.title, grouped.get(group.key));
}
if (other.length > 0) {
  printGroup('other (not conventional)', other);
}
