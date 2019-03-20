--[[
mytable = {} --普通表
mymetatable = {} --元表
setmetatable(mytable, mymetatable) --将mymetatable设为mytable的元表
]]
--以上代码可以写成一行
mytable = setmetatable({}, {})

--返回mymetatable
getmetatable(mytable)

--[[
__index用来访问表
]]
other = {foo = 3}
t = setmetatable({}, {__index = other})
print(t.foo, t.bar)
-- 3    nil
mytable =
    setmetatable(
    {key1 = "value1"},
    {
        __index = function(mytable, key)
            if key == "key2" then
                return "metatablevalue"
            else
                return nil
            end
        end
    }
)
print(mytable.key1, mytable.key2)
-- value1 metatablevalue
-- 可以将上面的代码简化如下
mytable = setmetatable({key1 = "value1", key2 = "value2"}, {__index = {key2 = "metatablevalue"}})
print(mytable.key1, mytable.key2)
-- value1  value2
--[[
通过__newindex元方法用来对表进行更新
]]
mymetatable = {}

mytable = setmetatable({key1 = "value1"}, {__newindex = mymetatable})
print(mytable.key1, mytable.key2)

--解释器就会查找__newindex 元方法：如果存在则调用这个函数而不进行赋值操作。
mytable.newkey = "new value2"
print(mytable.newkey, mymetatable.newkey)

--对已存在的索引键（key1），则会进行赋值，而不调用元方法 __newindex
mytable.key1 = "new value1"
print(mytable.key1, mymetatable.key1)

--使用rawset函数来更新表
mytable =
    setmetatable(
    {key1 = "value1"},
    {
        __newindex = function(mytable, key, value)
            rawset(mytable, key, '"' .. value .. '"')
        end
    }
)
mytable.key1 = "new value"
mytable.key2 = 4
print(mytable.key1, mytable.key2)
-- new value   "4"
--[[
为表添加操作符
]]
-- 自定义计算表中最大值函数 table_maxn
function table_maxn(t)
    local mn = 0
    for k, v in pairs(t) do
        if mn < k then
            mn = k
        end
    end
    return mn
end

-- 两表相加操作
mytable =
    setmetatable(
    {1, 2, 3},
    {
        __add = function(mytable, newtable)
            for i = 1, table_maxn(newtable) do
                table.insert(mytable, table_maxn(mytable) + 1, newtable[i])
            end
            return mytable
        end
    }
)
secondtable = {4, 5, 6}

mytable = mytable + secondtable
for k, v in ipairs(mytable) do
    print(k, v)
end

--[[
使用元方法__call调用值
]]
--计算表中元素的和
mytable =
    setmetatable(
    {10},
    {
        __call = function(mytable, newtable)
            sum = 0
            for i = 1, table_maxn(mytable) do
                sum = sum + mytable[i]
            end
            for i = 1, table_maxn(newtable) do
                sum = sum + newtable[i]
            end

            return sum
        end
    }
)
newtable = {10, 20, 30}
print(mytable(newtable))

--[[
使用__tostring元方法用于修改表的输出行为。
]]
mytable =
    setmetatable(
    {10, 20, 30},
    {
        __tostring = function(mytable)
            sum = 0
            for k, v in pairs(mytable) do
                sum = sum + v
            end

            return "表所有元素的和为" .. sum
        end
    }
)
print(mytable)
