import assert from 'node:assert/strict';

const baseUrl = process.env.API_BASE_URL ?? 'http://localhost:3000';
const email = process.env.BOOTSTRAP_ADMIN_EMAIL;
const password = process.env.BOOTSTRAP_ADMIN_PASSWORD;

assert.ok(email && password, 'Set BOOTSTRAP_ADMIN_EMAIL and BOOTSTRAP_ADMIN_PASSWORD in backend/.env');

async function request(path, { method = 'GET', token, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  return {
    status: response.status,
    body: response.headers.get('content-type')?.includes('application/json')
      ? await response.json()
      : await response.text(),
  };
}

const adminLogin = await request('/auth/login', {
  method: 'POST',
  body: { email, password },
});
assert.equal(adminLogin.status, 201, 'Admin login should work after the bootstrap migration');
assert.equal(adminLogin.body.role, 'admin');
const adminToken = adminLogin.body.accessToken;

const salaryList = await request('/admin/doctor-salaries', { token: adminToken });
assert.equal(salaryList.status, 200, 'Admin should be able to read salary summaries');

const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
const cccd = suffix.slice(-12).padStart(12, '1');
const patientEmail = `smoke-${suffix}@example.test`;
const invalidIdentity = await request('/auth/register', {
  method: 'POST',
  body: {
    email: `invalid-${suffix}@example.test`,
    password: 'smoke-test-password',
    name: 'Invalid Identity',
    gender: 'other',
    age: 31,
    birthDate: '1995-02-03',
    phone: '0900000000',
    address: 'Smoke test only',
    cccd: 'not-a-valid-cccd',
  },
});
assert.equal(invalidIdentity.status, 400, 'Invalid identity numbers should be rejected');

const register = await request('/auth/register', {
  method: 'POST',
  body: {
    email: patientEmail,
    password: 'smoke-test-password',
    name: 'Smoke Test Patient',
    gender: 'other',
    age: 31,
    birthDate: '1995-02-03',
    phone: '0900000000',
    address: 'Smoke test only',
    cccd,
  },
});
assert.equal(register.status, 201, 'A new patient should be able to register');
const patientToken = register.body.accessToken;

const profile = await request('/patient/me', { token: patientToken });
assert.equal(profile.status, 200);
assert.equal(profile.body.name, 'Smoke Test Patient');

const forbiddenAdminRoute = await request('/admin/doctor-salaries', { token: patientToken });
assert.equal(forbiddenAdminRoute.status, 403, 'Patient tokens must not access admin routes');

const unknownInsurance = await request('/auth/bhyt-lookup', {
  method: 'POST',
  body: { cccd: '999999999999', birthDate: '1990-01-01' },
});
assert.equal(unknownInsurance.status, 201);
assert.deepEqual(unknownInsurance.body, { found: false });

console.log('API smoke passed: admin login, patient validation/registration/profile, role guard, and BHYT lookup.');
