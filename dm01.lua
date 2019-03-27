--第一个lua程序
print("hello world")

function encode()
    print("hhh")
end

local array = {
    [2001] = encode -- 指定索引为2001时，值为encode函数
}

print(array[2001]())

for k, v in pairs(array) do
    print(k, v)
end
