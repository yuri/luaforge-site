require("lfs")
require("cosmo")
require("markdown")

local sandbox = require("saci.sandbox")

timestamp = os.date("%Y-%m-%dT%H:%M:%S-05:00", os.time())

SITEMAP_HEAD = [[<?xml version="1.0" encoding="UTF-8"?>
<urlset
      xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
            http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
<url>
  <loc>http://luaforge.net/</loc>
  <lastmod>]]..timestamp..[[</lastmod>
  <changefreq>monthly</changefreq>
</url>
]]

SITEMAP_TEMPLATE = [[
<url>
  <loc>http://luaforge.net/$dir/$item/</loc>
  <lastmod>]]..timestamp..[[</lastmod>
  <changefreq>monthly</changefreq>
</url>
]]

SITEMAP_FOOTER = [[
</urlset>
]]

OUTER_TEMPLATE = [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <link rel="shortcut icon" href="http://files.luaforge.net/luaforge-web/favicon.ico">
  <title>$title</title>
  <style>
   table {
     border-spacing: 0;
     border: 2px solid gray;
   }
   td {
     border: 1px solid gray;
     padding: .5em;
   }
   table.invisible {
     border: none;
   }
   table.invisible td {
     border: none;
   }

  </style>
 </head>
 <body style="background-color:#007">
 <a href="/"><img src="http://files.luaforge.net/luaforge-web/luaforge-logo-old.png" alt="luaforge logo"/></a>
 <div style="background-color:white; border:1px solid gray; margin: 10px; padding: 1em;">

<h1>$title</h1>

$content

</body>
</html>
]]

PROJECT_TEMPLATE = [[
<p>$abstract</p>

<table width="80%">
 <tr>
  <td width="30%"><b>Website:</b></td>
  <td>$website</td>
 </tr>
 <tr>
  <td><b>Admins:</b></td>
  <td>$owners</td>
 </tr>
 <tr>
  <td><b>Members:</b></td>
  <td>$creator</td>
 </tr>
 <tr>
  <td><b>License:</b></td>
  <td>$license</td>
 </tr>
 <tr>
  <td><b>Language:</b></td>
  <td>$language</a></td>
 </tr>
 <tr>
  <td><b>Tags:</b></td>
  <td>$tags</a></td>
 </tr>
 <tr>
  <td><b>OS:</b></td>
  <td>$os</a></td>
 </tr>
 <tr>
  <td><b>Registered:</b></td>
  <td>$registered</a></td>
 </tr>
 <tr>
  <td><b>Archived Mailing Lists:</b></td>
  <td>$lists</a></td>
 </tr>
 <tr>
  <td>
   <b>Archived Releases:</b><br/>
   <span style="font-size:10pt;font-style:italic">
    Archived releases may be out of date.
    See the project's current website for the latest releases.
   </span>
  </td>
  <td>$releases</a></td>
 </tr>
 <tr>
  <td><b>Source Repository:</b></td>
  <td>$source</a></td>
 </tr>
</table> 
]]

USER_TEMPLATE = [[
User's projects: 

<ul>
$projects
</ul>
]]

function save(filepath, title, content)
   local output_file, err = io.open(filepath, "w")
   local text = cosmo.f(OUTER_TEMPLATE){title=title, content=content}
   output_file:write(text)
   output_file:close()
end

-- Groups items in a list by the first letter.
function split_by_letter(items)
   local abc = "abcdefghijklmnopqrstuvwxyz"
   local items_by_letter = {}
   for i = 1, 26 do
      local letter = abc:sub(i,i)
      local buffer = {}
      for _, item in ipairs(items) do
         if item:sub(1,1) == letter then
            table.insert(buffer, item)
         end
      end
      table.insert(items_by_letter, {letter, buffer})
   end
   return items_by_letter
end

-- A function to organize links into columns
function make_columns_of_links(items, template)
   num_columns = 5
   items_per_column = math.ceil(#items / num_columns)
   buffer = "<table class='invisible' width='80%'><tbody valign='top'><tr>"
   minibuffer = ""
   columns_closed = 0
   for i, item in ipairs(items) do
      --print(i, items_per_column, item) 
      minibuffer = minibuffer..cosmo.f(template){i=item}.."<br/>"
      if i % items_per_column == 0 then
          buffer = buffer..[[<td width="20%">]]..minibuffer..[[</td>]]
          minibuffer = ""
          columns_closed = columns_closed+1
      end
   end
   buffer = buffer..[[<td width="20%">]]..minibuffer..[[</td>]]
   columns_closed = columns_closed+1
   for i = 1, num_columns - columns_closed do
      buffer = buffer..[[<td width="20%">&nbsp;</td>]]
   end
   return buffer.."</tr></tbody></table>"
end


-- Some simple helper functions.
function link_url(url)
   if url then
     return '<a href="'..url..'">'..url..'</a>'
   else
     return "n.a."
   end
end

function space_items(list)  
  return list and list:gsub(",", ", ") or "--"
end


function trim (s)
   return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- Associate a project with a tag
local tags = {}
function tag_project(p, tags_list)

  if tags_list == "--" then
     return
  end
  tags_list = tags_list..","
  buffer = ""
  for t in string.gmatch(tags_list, "(.-),") do
     t = trim(t)
     tags[t] = tags[t] or {}
     table.insert(tags[t], p)
  end
end


-- Associate a project with a user and produce a link
user_to_project = {}
function link_users(list, project)
  list = list..","
  buffer = ""
  for u in string.gmatch(list, "(%w+),") do
     buffer= buffer..'<a href="/users/'..u..'">'..u..'</a> '
     user_to_project[u] = user_to_project[u] or {}
     user_to_project[u][project] = 1
  end
  return buffer
end


local sitemap = io.open("output/sitemap.xml", "w")
sitemap:write(SITEMAP_HEAD)


-- Go through projects and generate individual pages.
projects = {}
for pfile in lfs.dir("projects/") do
  if pfile~="." and pfile~=".." then
    local p = pfile:sub(0,pfile:len()-4)
    print(p, #projects)
    table.insert(projects, p)
    print(p, #projects)
    local f, err = io.open("projects/"..pfile)
    local code = f:read("*all")
    s = sandbox.new()
    s:do_lua(code)

    v = s.values
    v.releases = v.releases and markdown(v.releases) or "n.a."
    v.lists = v.lists and markdown(v.lists) or "n.a."

    v.website = link_url(v.website)
    v.source = link_url(v.source)
    v.creator = link_users(v.creator, p)
    v.owners = link_users(v.owners, p)
    v.tags = space_items(v.tags)
    tag_project(p, v.tags)

    v.content = cosmo.f(PROJECT_TEMPLATE)(v)

    lfs.mkdir("output/projects/"..p)
    save("output/projects/"..p.."/index.html", v.title, v.content)

    sitemap:write(cosmo.f(SITEMAP_TEMPLATE){dir="projects", item=p})
  end
end

-- Generate user pages.
users = {}
for user, phash in pairs(user_to_project) do
   l = {}
   table.insert(users, user)
   for project, _ in pairs(phash) do
      l[#l+1]=project
   end
   table.sort(l)
   buffer = ""
   
   for i,p in ipairs(l) do
      buffer = buffer..'<li><a href="/projects/'..p..'">'..p..'</a>'
   end

   v = {}
   v.projects = buffer

   lfs.mkdir("output/users/"..user)
   
   save("output/users/"..user.."/index.html", user, cosmo.f(USER_TEMPLATE)(v))
   sitemap:write(cosmo.f(SITEMAP_TEMPLATE){dir="users", item=p})
end

sitemap:write(SITEMAP_FOOTER)

print ("--------------")

-- Generate an index of users.
table.sort(users)
users_by_letter = split_by_letter(users)
buffer = ""
for i, v in ipairs(users_by_letter) do
   local letter = v[1]
   local users = v[2]
   buffer = buffer
            .."\n\n<h2>"..letter.."</h2>\n\n"
            ..make_columns_of_links(users,
                                    '<a href="/users/$i/">$i</a>\n')
end
save("output/users/index.html", "Users", buffer)

-- Save the list of projects by tag.
local tag_list = {}
for tag, list in pairs(tags) do
   table.insert(tag_list, tag)
   table.sort(tag_list, function(x,y) return #tags[x]>#tags[y] end)
end

buffer = ""
for i, tag in ipairs(tag_list) do
   buffer = buffer.."\n\n<h2>"..tag.."</h2>\n\n"
   table.sort(tags[tag])
   
   buffer = buffer..make_columns_of_links(tags[tag],
                                   '<a href="/projects/$i/">$i</a>\n')
end
buffer=[[
(For an alphabetical list of all projects, click <a href="/projects/">here</a>.)
]]..buffer
save("output/tags/index.html", "Projects by Tag", buffer)



-- Save the project catalog index page.
table.sort(projects)
buffer = [[
<p>For a listing of projects by tags click <a href="/tags/">here</a>.</p>
]]

projects_by_letter = split_by_letter(projects)
for i, v in ipairs(projects_by_letter) do
   local letter = v[1]
   local projects = v[2]
   buffer = buffer
            .."\n\n<h2>"..letter.."</h2>\n\n"
            ..make_columns_of_links(projects,
                                    '<a href="/projects/$i/">$i</a>\n')
end
save("output/projects/index.html", "Project Catalog", buffer)

