--[[
coroutine的用法
]]
--[[
coroutine.create() 创建coroutine，返回coroutine，参数是
一个函数，当和resume配合使用的时候就唤醒函数调用
]]
co =
    coroutine.create(
    function(i)
        print(i)
    end
)
-- 重启coroutine，和create配合使用
coroutine.resume(co, 1)
-- 1
-- 查看coroutine的状态：dead、suspend和running
print(coroutine.status(co))
--dead

print("--------------------------------")

--[[
    创建coroutine，返回函数，一但调用此函数就进入
    coroutine，和create功能重复
]]
co =
    coroutine.wrap(
    function(i)
        print(i)
    end
)
co(1)

print("-----------------------------------")

--[[
    coroutine.running():
        返回正在跑的coroutine，一个coroutine就是一个线程，
        当使用running的时候，就是返回一个corouting的线程号
    coroutine.yield():
        挂起coroutine，将coroutine设置为挂起状态，这个和
        resume配合使用能有很多有用的效果
]]
co2 =
    coroutine.create(
    function()
        for i = 1, 10 do
            print(i)
            if i == 3 then
                print(coroutine.status(co2)) -- running
                print(coroutine.running()) -- thread:XXXXXX
            end
            coroutine.yield()
        end
    end
)

coroutine.resume(co2) -- 1
coroutine.resume(co2) -- 2
coroutine.resume(co2) -- 3

print(coroutine.status(co2)) -- suspended
print(coroutine.running()) -- nil
