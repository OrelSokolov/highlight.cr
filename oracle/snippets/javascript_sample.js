// Главный модуль приложения
import { format, parse } from './utils.js';
const VERSION = '2.1.0';

export class ApiClient {
  #cache = new Map();
  static instances = 0;

  constructor(baseUrl = 'https://api.example.com') {
    this.baseUrl = baseUrl;
    ApiClient.instances++;
  }

  async fetchUsers({ page = 1, limit = 10 } = {}) {
    const key = `users:${page}`;
    if (this.#cache.has(key)) return this.#cache.get(key);
    try {
      const res = await fetch(`${this.baseUrl}/users?page=${page}&limit=${limit}`);
      const { data, total = 0 } = await res.json();
      this.#cache.set(key, data);
      return data.filter(u => u.age >= 18).map(u => ({ ...u, name: u.name.trim() }));
    } catch (err) {
      console.error(`Ошибка: ${err.message}`, err);
      throw err;
    } finally {
      console.timeEnd('fetch');
    }
  }
}

const tpl = (name) => `Hello, ${name}!`;
const html = /* html */ `<div class="x">${VERSION}</div>`;
const gql = /* GraphQL */ `{ user(id: 1) { name } }`;
const re = /^[\w.-]+@\w+\.\w{2,}$/gi;
let big = 0x1Fn, oct = 0o755, num = 1_000.5e-3;

function* ids(start = 0) {
  while (true) yield start++;
}

export default async function main() {
  const client = new ApiClient();
  const users = await client.fetchUsers({ page: 2 });
  const [first, ...rest] = users ?? [];
  for await (const u of rest) format(u?.name ?? 'anon');
  await new Promise(r => setTimeout(r, 100));
  return users.length;
}
