// k6 load test — account cycle (login → me → refresh, teardown → logout).
//
// Covers only /api/v1/account and /api/v1/auth — the two routers guaranteed
// to exist in any project built from this template (core/auth). Add a
// sibling scenario file per feature/endpoint that needs load testing —
// see ../README.md for when that's warranted and how to wire it in.
//
// Run:
//   k6 run --env BASE_URL=http://localhost:3000/api/v1 loadtest/k6/account_cycle.js
//
// BASE_URL must include /api/v1, same as this project's own BASE_URL env
// value (see .env.{flavor}.json / lib/core/infra/config/env.dart).

import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL;
if (!BASE_URL) {
  throw new Error('Set --env BASE_URL=<...> (must include /api/v1)');
}

// POOL_SIZE is capped by the backend's register rate limit: 5 registrations
// per hour per source IP (registerRateLimit, backend_template/src/core/
// middleware/register-rate-limit.ts). Running k6 from one machine means one
// IP — going above 5 here will 429 on setup(). Raise it only if you've
// changed that limit for this environment, or seeded users directly in the
// database instead of through this script (see ../README.md).
const POOL_SIZE = Number(__ENV.POOL_SIZE || 5);

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '2m', target: 20 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

function authHeaders(token) {
  return { headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } };
}

// Idempotent: a user already registered from a previous run just logs in.
// Keeps setup() safe to re-run without burning the register quota again.
function loginOrRegister(email, password) {
  const loginRes = http.post(
    `${BASE_URL}/account/login`,
    JSON.stringify({ email, password }),
    { headers: { 'Content-Type': 'application/json' } },
  );
  if (loginRes.status === 200) {
    return loginRes.json('data.token');
  }

  const registerRes = http.post(
    `${BASE_URL}/account/register`,
    JSON.stringify({ email, password, full_name: 'k6 Load Test' }),
    { headers: { 'Content-Type': 'application/json' } },
  );
  check(registerRes, { 'register ok or already exists': (r) => r.status === 200 || r.status === 201 });

  const retryRes = http.post(
    `${BASE_URL}/account/login`,
    JSON.stringify({ email, password }),
    { headers: { 'Content-Type': 'application/json' } },
  );
  check(retryRes, { 'login after register: 200': (r) => r.status === 200 });
  return retryRes.json('data.token');
}

export function setup() {
  const users = [];
  for (let i = 0; i < POOL_SIZE; i++) {
    const email = `k6-loadtest-${i}@example.test`;
    const password = 'LoadTest12345';
    const token = loginOrRegister(email, password);
    users.push({ email, token });
  }
  return { users };
}

export default function (data) {
  const user = data.users[__VU % data.users.length];

  const meRes = http.get(`${BASE_URL}/account/me`, authHeaders(user.token));
  check(meRes, { 'me: 200': (r) => r.status === 200 });

  sleep(Math.random() * 2 + 1);

  // Exercise token refresh from a fraction of iterations only — it rotates
  // the token, and every VU here shares POOL_SIZE tokens.
  if (Math.random() < 0.2) {
    const refreshRes = http.post(`${BASE_URL}/auth/refresh`, null, authHeaders(user.token));
    check(refreshRes, { 'refresh: 200': (r) => r.status === 200 });
  }

  sleep(Math.random() * 2 + 1);
}

export function teardown(data) {
  for (const user of data.users) {
    http.post(`${BASE_URL}/account/logout`, null, authHeaders(user.token));
  }
}
