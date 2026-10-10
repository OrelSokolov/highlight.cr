// API-клиент с типами
import type { AxiosRequestConfig } from 'axios';

export interface User<ID extends string | number = number> {
  id: ID;
  name: string;
  email?: string;
  readonly roles: readonly Role[];
  createdAt: Date;
}

export type Role = 'admin' | 'user' | (string & {});
type Predicate<T> = (value: T, index: number) => value is T;

declare global {
  interface Window { __APP__?: App }
}

export abstract class Client<T extends object = {}> {
  protected constructor(
    private readonly baseUrl: string,
    public config: AxiosRequestConfig = {},
  ) {}

  abstract fetch<T>(path: `/${string}`): Promise<T>;

  async findUsers<K extends keyof User>(key: K, pick: K[]): Promise<Pick<User, K>> {
    const params = { key, pick } as const satisfies Record<string, K[]>;
    let result!: Pick<User, K>;
    try {
      const res = await this.fetch<User>(`/users/${String(key)}`);
      result = { [key]: res[key] } as Pick<User, K>;
    } catch (e) {
      if (e instanceof Error) console.error(e.message);
      throw e satisfies never;
    }
    const fn = <U,>(x: U | undefined): U => x!;
    return result;
  }
}

enum Status { Active, Paused = 5, Done }

export function assert<T>(cond: T extends true ? true : false): void {}
export const total = 10 as const;
let big = 0x1Fn, tpl = `id-${total}`;
