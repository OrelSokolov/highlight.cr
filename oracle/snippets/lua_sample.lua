-- Основной модуль
local json = require("cjson")
local M = {}

M.VERSION = "1.0.0"
local counter = 0

function M.new(name, options)
  options = options or {}
  local self = setmetatable({}, { __index = M })
  self.name = name or "default"
  self.options = options
  return self
end

function M:greet(prefix)
  return string.format("%s, %s!", prefix or "Hello", self.name)
end

local function fib(n)
  if n < 2 then return n end
  return fib(n - 1) + fib(n - 2)
end

for i = 1, 10 do
  counter = counter + i
end

local t = { 1, 2, 3, x = 10, ["ключ"] = "значение" }
for k, v in pairs(t) do print(k, v) end

local ok, err = pcall(function() error("oops") end)
print(#t, 0x1F, 3.14e2, 1/0, counter, fib(10), M:greet("Привет"), ok and err)
