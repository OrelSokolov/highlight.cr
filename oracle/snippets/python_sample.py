#!/usr/bin/env python3
"""Модуль пользователей."""
from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass, field
from typing import Any, ClassVar

VERSION: str = "1.2.0"
NAME_RE = re.compile(r"^[A-Za-zА-Яа-яёЁ_-]{2,}$")


@dataclass(frozen=True)
class User:
    name: str
    age: int = 0
    tags: list[str] = field(default_factory=list)
    MAX: ClassVar[int] = 100

    @property
    def is_adult(self) -> bool:
        return self.age >= 18


class UserService:
    def __init__(self, users: list[User] | None = None):
        self._users = users or []

    async def find(self, pattern: str = r"\w+", *, limit: int | None = None) -> dict[str, Any]:
        async def fetch():
            await asyncio.sleep(0)
            return {u.name: u.age for u in self._users if re.match(pattern, u.name)}

        result = await fetch()
        return dict(list(result.items())[:limit]) if limit is not None else result

    @staticmethod
    def fib(n: int) -> int:
        a, b = 0, 1
        for _ in range(n):
            a, b = b, a + b
        return a


if __name__ == "__main__":
    svc = UserService([User("Олег", 30), User("Anna", 0b101)])
    print(f"{svc.fib(10)=}, {0x1F=}, {1_000_000:,}")
    print([x**2 for x in range(10) if x % 2 == 0], lambda *args, **kw: None)
