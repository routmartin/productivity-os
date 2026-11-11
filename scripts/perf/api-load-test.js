// k6 load test for the Productivity OS API read-heavy hot paths.
//
// Exercises the endpoints a logged-in user hits most often: task lists,
// projects, goals, daily plan, top three and focus sessions. Each virtual
// user owns a dedicated account so responses are isolated.
//
// Quick start (API running locally on :8080):
//   k6 run scripts/perf/api-load-test.js
//   # or, with the wrapper that checks prerequisites:
//   ./scripts/perf/run.sh
//   # or:
//   make perf
//
// Common overrides (pass with -e KEY=VALUE):
//   BASE_URL            API base URL                     (default http://localhost:8080)
//   PEAK_VUS            peak concurrent users            (default 20)
//   RAMP_UP / HOLD / RAMP_DOWN   stage durations         (default 30s / 1m / 20s)
//   NUM_USERS           test accounts provisioned        (default = PEAK_VUS)
//   THINK_TIME          seconds to sleep between requests (default 0)
//   DATE                date for daily-plan/top-three    (default today, UTC)
//   RUN_ID              suffix to isolate a run's users  (default now)
//   TEST_PASSWORD       test account password (>=12)     (default perf-test-password-123)
//   CREDS_FILE          file of "email,password" lines to reuse existing accounts
//   ALLOW_REGISTER      "true" to permit auto-registration on a non-local host
//
// RUNNING AGAINST A REAL/DEPLOYED API:
//   Reuse real accounts instead of creating them:
//     k6 run -e BASE_URL=https://<host> -e CREDS_FILE=/abs/path/creds.csv \
//            -e PEAK_VUS=100 -e HOLD=3m scripts/perf/api-load-test.js
//   The script refuses to auto-register against a non-local host unless
//   ALLOW_REGISTER=true. Credentials are read from the file only; they are
//   never written to the output.
//
// NOTE ON TOKENS: the API signs access tokens with a short TTL
// (JWT_ACCESS_TOKEN_TTL_MINUTES, 1 minute by default). This script keeps a
// per-VU session and re-logs-in before that TTL elapses, and retries once on
// a 401. For cleaner latency numbers, raise the TTL when starting the API:
//   JWT_ACCESS_TOKEN_TTL_MINUTES=60 ./gradlew :apps:api:bootRun
// and run with -e TOKEN_TTL_SECONDS=3000.
//
// Example heavy run:
//   k6 run -e PEAK_VUS=100 -e HOLD=3m -e RAMP_UP=1m scripts/perf/api-load-test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const BASE_URL = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/+$/, '');
const PEAK_VUS = Number(__ENV.PEAK_VUS || 20);
const RAMP_UP = __ENV.RAMP_UP || '30s';
const HOLD = __ENV.HOLD || '1m';
const RAMP_DOWN = __ENV.RAMP_DOWN || '20s';
const NUM_USERS = Math.max(1, Number(__ENV.NUM_USERS || PEAK_VUS));
const THINK_TIME = Number(__ENV.THINK_TIME || 0);
const DATE = __ENV.DATE || new Date().toISOString().slice(0, 10);
const TOKEN_TTL_SECONDS = Number(__ENV.TOKEN_TTL_SECONDS || 55);

const PASSWORD = __ENV.TEST_PASSWORD || 'perf-test-password-123';
const EMAIL_PREFIX = __ENV.TEST_EMAIL_PREFIX || 'perf';
const EMAIL_DOMAIN = __ENV.TEST_EMAIL_DOMAIN || 'perf.local';
const RUN_ID = __ENV.RUN_ID || Date.now().toString(36);

// Existing-credentials mode: a file of "email,password" lines (blank lines and
// lines starting with # are ignored). When set, setup() does NOT register any
// accounts — required for any non-local target.
const CREDS_FILE = __ENV.CREDS_FILE || '';
const IS_LOCAL_TARGET = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:[0-9]+)?$/i.test(BASE_URL);
const ALLOW_REGISTER = String(__ENV.ALLOW_REGISTER || '').toLowerCase() === 'true';

if (PASSWORD.length < 12) {
  throw new Error('TEST_PASSWORD must be at least 12 characters (API validation).');
}

function parseCredsFile(raw) {
  const creds = [];
  raw.split('\n').forEach((line, i) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const idx = trimmed.indexOf(',');
    if (idx === -1) {
      throw new Error(`CREDS_FILE line ${i + 1} must be "email,password"`);
    }
    creds.push({
      email: trimmed.slice(0, idx).trim(),
      password: trimmed.slice(idx + 1),
    });
  });
  return creds;
}

// open() is only valid in the init context; each VU reads the file once.
const FILE_USERS = CREDS_FILE ? parseCredsFile(open(CREDS_FILE)) : [];

if (CREDS_FILE && FILE_USERS.length === 0) {
  throw new Error(`CREDS_FILE "${CREDS_FILE}" contained no usable credentials.`);
}
if (!IS_LOCAL_TARGET && FILE_USERS.length === 0 && !ALLOW_REGISTER) {
  throw new Error(
    `Refusing to auto-register users against non-local API ${BASE_URL}. ` +
      'Pass CREDS_FILE=/abs/path/creds.csv, or ALLOW_REGISTER=true to override.'
  );
}

// The API only returns 404 for "no data yet" endpoints; 200/201/204 and 404
// are all legitimate, so keep them out of http_req_failed. Anything else
// (401/5xx) counts as a failure.
http.setResponseCallback(http.expectedStatuses(200, 201, 204, 404));

// ---------------------------------------------------------------------------
// Weighted read endpoints (weight ~= share of total traffic)
// ---------------------------------------------------------------------------
const ENDPOINTS = [
  { tag: 'tasks', path: () => '/api/v1/tasks?page=0&size=20', weight: 6, allow404: false, auth: true },
  { tag: 'tasks_completed', path: () => '/api/v1/tasks/completed?page=0&size=50', weight: 3, allow404: false, auth: true },
  { tag: 'projects', path: () => '/api/v1/projects', weight: 4, allow404: false, auth: true },
  { tag: 'goals', path: () => '/api/v1/goals', weight: 4, allow404: false, auth: true },
  { tag: 'daily_plan', path: () => `/api/v1/daily-plan/${DATE}`, weight: 4, allow404: true, auth: true },
  { tag: 'top_three', path: () => `/api/v1/daily-top-three/${DATE}`, weight: 3, allow404: true, auth: true },
  { tag: 'focus_active', path: () => '/api/v1/focus/active', weight: 3, allow404: true, auth: true },
  { tag: 'focus_list', path: () => '/api/v1/focus?page=0&size=20', weight: 3, allow404: false, auth: true },
  { tag: 'health', path: () => '/api/v1/health', weight: 1, allow404: false, auth: false },
];
const TOTAL_WEIGHT = ENDPOINTS.reduce((sum, e) => sum + e.weight, 0);

// ---------------------------------------------------------------------------
// Custom metrics
// ---------------------------------------------------------------------------
const unexpectedResponses = new Rate('unexpected_responses');
const authLatency = new Trend('auth_login_duration', true);

// ---------------------------------------------------------------------------
// k6 options
// ---------------------------------------------------------------------------
export const options = {
  scenarios: {
    read_hot_paths: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: RAMP_UP, target: PEAK_VUS },
        { duration: HOLD, target: PEAK_VUS },
        { duration: RAMP_DOWN, target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  setupTimeout: '5m',
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    unexpected_responses: ['rate<0.01'],
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    'http_req_duration{endpoint:health}': ['p(95)<100'],
    'http_req_duration{endpoint:tasks}': ['p(95)<300'],
    'http_req_duration{endpoint:tasks_completed}': ['p(95)<400'],
    'http_req_duration{endpoint:projects}': ['p(95)<300'],
    'http_req_duration{endpoint:goals}': ['p(95)<300'],
    'http_req_duration{endpoint:daily_plan}': ['p(95)<400'],
    'http_req_duration{endpoint:top_three}': ['p(95)<400'],
    'http_req_duration{endpoint:focus_active}': ['p(95)<300'],
    'http_req_duration{endpoint:focus_list}': ['p(95)<400'],
  },
};

// ---------------------------------------------------------------------------
// Per-VU session state (module-scope variables persist across iterations)
// ---------------------------------------------------------------------------
let token = null;
let tokenIssuedAt = 0;
let users = null;

function login(user) {
  const res = http.post(
    `${BASE_URL}/api/v1/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { endpoint: 'auth_login' },
    }
  );
  authLatency.add(res.timings.duration);
  if (res.status === 200) {
    token = res.json('accessToken');
    tokenIssuedAt = Date.now();
    return token;
  }
  token = null;
  return null;
}

function currentToken(user) {
  if (!token || Date.now() - tokenIssuedAt > TOKEN_TTL_SECONDS * 1000) {
    return login(user);
  }
  return token;
}

function pickEndpoint() {
  let r = Math.random() * TOTAL_WEIGHT;
  for (const endpoint of ENDPOINTS) {
    r -= endpoint.weight;
    if (r <= 0) return endpoint;
  }
  return ENDPOINTS[0];
}

function request(endpoint, user) {
  const url = `${BASE_URL}${endpoint.path()}`;
  const headers = {};
  if (endpoint.auth) {
    const t = currentToken(user);
    if (!t) return null;
    headers.Authorization = `Bearer ${t}`;
  }

  let res = http.get(url, { headers, tags: { endpoint: endpoint.tag } });

  if (res.status === 401 && endpoint.auth) {
    // Token expired or revoked mid-run: re-authenticate once and retry.
    const t = login(user);
    if (t) {
      res = http.get(url, {
        headers: { Authorization: `Bearer ${t}` },
        tags: { endpoint: endpoint.tag },
      });
    }
  }
  return res;
}

// ---------------------------------------------------------------------------
// Setup: use supplied credentials, or provision one account per virtual user.
// ---------------------------------------------------------------------------
export function setup() {
  if (FILE_USERS.length > 0) {
    // Fail fast if the first credential does not authenticate.
    const probe = http.post(
      `${BASE_URL}/api/v1/auth/login`,
      JSON.stringify({ email: FILE_USERS[0].email, password: FILE_USERS[0].password }),
      { headers: { 'Content-Type': 'application/json' }, tags: { endpoint: 'setup_verify' } }
    );
    if (probe.status !== 200) {
      throw new Error(
        `CREDS_FILE credential ${FILE_USERS[0].email} failed to log in (HTTP ${probe.status}).`
      );
    }
    return { users: FILE_USERS };
  }

  const provisioned = [];
  for (let i = 0; i < NUM_USERS; i++) {
    const email = `${EMAIL_PREFIX}-${RUN_ID}-${i}@${EMAIL_DOMAIN}`;
    const res = http.post(
      `${BASE_URL}/api/v1/auth/register`,
      JSON.stringify({ email, password: PASSWORD, timezone: 'UTC' }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { endpoint: 'setup_register' },
      }
    );
    if (res.status !== 201) {
      console.error(`register failed for ${email}: HTTP ${res.status} ${res.body}`);
    }
    provisioned.push({ email, password: PASSWORD });
  }
  return { users: provisioned };
}

// ---------------------------------------------------------------------------
// Default: pick a weighted endpoint and read it.
// ---------------------------------------------------------------------------
export default function (data) {
  if (!users) users = data.users;
  const user = users[(__VU - 1) % users.length];
  const endpoint = pickEndpoint();

  const res = request(endpoint, user);
  if (res === null) {
    unexpectedResponses.add(1);
    return;
  }

  const ok = check(res, {
    [`${endpoint.tag} ok`]: (r) => r.status === 200 || (endpoint.allow404 && r.status === 404),
  });
  unexpectedResponses.add(!ok);

  if (THINK_TIME > 0) sleep(THINK_TIME);
}
