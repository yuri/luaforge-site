title = "lsqlite"
prototype      = "@Project"
releases = [[
* [lsqlite](http://files.luaforge.net/releases/lsqlite/lsqlite)
]]
owners = "nico"
creator = "nico"
abstract = [[
a simple libsqlite3 binding for lua5.0-5.2 that provides 3 functions only and is still fully functional:

local db = lsqlite.open(database)
results, err = db:exec(statments)
db:close()
]]
license = "MIT/X"
language = "c, lua 5"
tags = "database"
activity = "33.65%"
registered = "2010-06-01 16:23"
website = "http://luaforge.net/projects/lsqlite/"
