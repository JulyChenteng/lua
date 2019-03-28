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
                    print(coroutine.status(co2))
                    -- running
                    print(coroutine.running())
                -- thread:XXXXXX
                end
                coroutine.yield()
            end
        end
)
coroutine.resume(co2)
-- 1
coroutine.resume(co2)
-- 2
coroutine.resume(co2)
-- 3
print(coroutine.status(co2))
-- suspended
print(coroutine.running())
-- nil
print("----------------------------------------------------------------------------")
print("----------------------------------------------------------------------------")

--[[
resume和yield的配合强大之处在于，resume处于主程中，它将外部状态（数据）传入到协同程序内部；
而yield则将内部的状态（数据）返回到主程中。
]]
function foo(a)
    print("foo函数输出", a)
    return coroutine.yield(2 * a)
-- 返回 2*a 的值
end

co =
    coroutine.create(
        function(a, b)
            print("第一次协同程序执行输出", a, b)
            -- co-body 1 10
            local r = foo(a + 1)
            
            print("第二次协同程序执行输出", r)
            local r, s = coroutine.yield(a + b, a - b)
            -- a, b的值为第一次调用协同程序时传入的
            print("第三次协同程序执行输出", r, s)
            return b, "结束协同程序" -- b的值为第二次调用协同程序时传入的
        end
)
print("main", coroutine.resume(co, 1, 10))
-- true, 4
print("----------------------")
print("main", coroutine.resume(co, "r"))
--true 11 -9
print("----------------------")
print("main", coroutine.resume(co, "x", "y"))
-- true 10 end
print("----------------------")
print("main", coroutine.resume(co, "x", "y"))
-- cannot resume dead coroutine
print("----------------------")

--[[
生产者-消费者问题
]]
print("---------------------------生产者-消费者问题------------------")
local newProductor

function productor()
    local i = 0
    while true do
        i = i + 1
        send(i)-- 将产品发送给消费者
    end
end

function consumer()
    while true do
        local i = receive()-- 接收生产者发送来的产品
        print(i)
    end
end

function receive()
    local status, value = coroutine.resume(newProductor)
    return value
end

function send(x)
    coroutine.yield(x)-- x表示需要发送的值，值返回以后就挂起该协同程序
end

newProductor = coroutine.create(productor)
consumer()
