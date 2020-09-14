## Description

  Simple Lua/MTA argument type checking lib for MTA:SA.

## API

### Functions

- `void check(string patern)`
  Check function arguments by pattern. It causes an error "bad argument" if the check failed.
  
- `boolean scheck(string pattern)`
  Soft check function arguments by pattern. It causes a warning "bad argument" and returns 'false' if the check failed, otherwise returns 'true'.
  
- `boolean warn(string msg [, int lvl = 1])`
  Cause a warning. Unlike 'error', doesn't terminate the function. Unlike outputDebugString, u can define Lua warning lvl. 
  
### Variables

- `table checkers`
  Table of user custom checkers.

## How to use

### Patterns

#### Lua types shortcuts

  Use types shortcuts instead full type names:

```lua
check("boolean") -- сheck whether the arg #1 is a boolean
check("b") -- same
  
check("nil") -- nil type doesn't have shortcut
  
check("number")
check("n")
  
check("string")
check("s")
  
check("table")
check("t")
  
check("userdata")
check("u")
  
check("function")
check("f")
  
check("thread")
check("th")
```

#### Multiple args

  Use as many arguments types as you need:
  
```lua
check("s,n,t") -- #1 - string, #2 - number, #3 - table
```

#### Special symbols

  Use 'any' type by '?' symbol or 'notnil' type by '!' symbol:

```lua
check("s,?,t") -- #1 - string, #2 - any type, #3 - table
check("s,n,!") -- #1 - string, #2 - number, #3 - any type but NOT nil
```

#### Optional args

  Use optional arguments by '?' symbol:
  
```lua
check("s,?n,t") -- #1 - string, #2 - nil or number(optional argument), #3 - table
```

#### Type variants

  Use two or more variants of type separated by '|' symbol:

```lua
check("nil|s,n,t") -- #1 - nil or string(optional argument), #2 - number, #3 - table
check("?s,n,t") -- same
check("s|n|t,t") -- #1 - string or number or table, #2 - table
check("?s|n|t,t") -- #1 - nil or string or number or table(optional argument), #2 - table
```

#### Type repeat

  Use two or more same types by '[n]' block:
  
```lua
check("s,n[2],t") -- #1 - string, #2 - number, #3 - number, #4 - table
check("s,b|n[2],t") -- #1 - string, #2 - boolean or number, #3 - boolean or number, #4 - table
check("s,?b|n[2],t") -- #1 - string, #2 - nil or boolean or number(optional argument), #3 - nil or boolean or number(optional argument), #4 - table
```

#### Metatable types

  Use metatable types
  
```lua
function f(c)
    check("color")
    return true
end

function test()
    local red = setmetatable({255, 0, 0}, {__type = "color"})
    iprint(f(red)) -- true
end
```

#### MTA types

  Use userdata MTA types as subtypes of 'userdata':
  
```lua
check("u:acl-group") -- #1 - acl-group
check("u:lua-timer") -- #1 - timer
```

  Use MTA element types as subtypes of 'userdata:element':
  
```lua
check("u:element:vehicle") -- #1 - vehicle element
check("u:element:player|u:element:ped") -- #1 - player element or ped element
```

  GUI elements default checker is available:
  
```lua
check("userdata:element:gui") -- #1 - any MTA gui element (button, label, gridlist, etc...)
check("u:element:gui") -- same
```

### Check

#### Hard check

  It causes Lua error "bad argument" if the check failed:
  
```lua
function f(str, num, data)
    check("s,?n,t") -- #1 - string, #2 - nil or number(optional argument), #3 - table
    return true
end

function test()
    iprint(f("lol", 1, {})) -- true
    iprint(f("lol", nil, {})) -- true
    iprint(f("lol", nil, nil)) -- error: bad argument #3 'data' to 'f' (table expected, got nil)
end
```

#### Soft check

  It causes a warning "bad argument" and returns 'false' if the check failed, otherwise returns 'true':
  
```lua
function f(str, num, data)
    if not scheck("s,?n,t") then return false end
    return true
end

function test()
    iprint(f("lol", 1, {})) -- true
    iprint(f("lol", nil, {})) -- true
    iprint(f("lol", nil, nil)) -- false, warning: bad argument #3 'data' to 'f' (table expected, got nil)
end
```
  
#### Custom checkers

  Define your own checkers:
  
```lua
function f(num)
    check("percent")
    return true
end

function test()
    checkers.percent = function(v) return type(v) == "number" and v >= 0 and v <= 1 end
    iprint(f(0.1)) -- true
    iprint(f(1)) -- true
    iprint(f(1.1)) -- error: bad argument #3 'num' to 'f' (percent expected, got number)
end
```

#### Warnings

  Use warnings instead errors wherever you need:
  
```lua
function f()
    warn("something is wrong, but that's all right", 2)
    return true
end

function test()
    iprint(f()) -- true, warning: something is wrong, but that's all right
end
```
