local cfg = {}
local table_def = {}
local table_info = {}
local types = {
    mchar = "tinyint",
    mint1 = "tinyint",
    mint2 = "smallint",
    mint4 = "int",
    mint8 = "bigint",
    mchararry = "char",
}
local parse_error = false

local data_table = {}
local field_split_save = false  -- 字段是否拆分存储
local table_num = 3           -- 数据表数量
 
local function init()
    cfg.index_optimize = false
    cfg.file_prefix = "dump_mdb_table"
    cfg.namespace = "dup_mdb"
    cfg.db_name = "DUP_MDB"
    cfg.db_engine = "MDB"
    cfg.cpp_headfile = cfg.file_prefix .. ".h"
    cfg.cpp_headfile_guard = string.format("_%s_H_", string.upper(cfg.file_prefix))
    cfg.sql_createfile = cfg.file_prefix .. ".create.sql"
    cfg.sql_constraintfile = cfg.file_prefix .. ".constraint.sql"
    cfg.autogen_info = "This is a auto-generated file, DON\'T MODIFY IT!"
end

if field_split_save then
    data_table = {
        name = "CTest",
        fields = [[
            mint8 m_llCustId;
            mint2 m_nCustType;
            mint2 m_nRegionCode;
            mint2 m_nGender;
            mint2 m_nOccupation;
            mint2 m_nCustClass;
            mint2 m_nCustSegment;
            mint2 m_nCustStatus;
            mint4 m_dBirthday;
            mint4 m_dCreateDate;	
            mint4 m_dValidDate;	//seconds
            mint4 m_dExpireDate;	//seconds
        ]],
        indexs = {
            "m_llCustId",
        },
        pk = "m_llCustId, m_dValidDate",
    }
else
    data_table = {
        name = "CTest",
        fields = [[
            mint8 m_llCustId;
            mint2 m_nCustType;
            mint4 m_dValidDate;	//seconds
        ]],
        indexs = {
            "m_llCustId",
        },
        pk = "m_llCustId, m_dValidDate",
    }
end

-- 实现table类型深拷贝
function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

for i = 0,table_num-1,1
do
    local tmp_table = deepCopy(data_table) 
    tmp_table["name"] = data_table["name"].."_"..i
    table.insert(table_def, tmp_table)
end

local function trim(s)
    return string.gsub(string.gsub(s, "^%s+", ""), "%s+$", "")
end

local function remove_comment_and_newline(text)
    local s = text .. "\n"
    s = string.gsub(s, "/%*.-%*/", "")
    s = string.gsub(s, "//.-[\r\n]", "")
    s = string.gsub(s, "[\r\n]", "")
    return s
end

local function is_valid_type(vartype)
    if types[vartype] then
        return true
    else
        return false
    end
end

local function split_fieldname(name)
    local t = {}
    if string.sub(name, 1, 2) == "m_" then
        for x in string.gmatch(name, "([%u][%u]?[%l0-9]*)") do
            table.insert(t, string.lower(x))
        end
    else
        table.insert(t, name)
    end
    return t
end

local function parse_one_field(vartype, varname)
    local t = {}
    if not is_valid_type(vartype) then
        return nil
    end
    t.type = vartype
    t.type_in_mysql = types[vartype]
    local from, to, len = string.find(varname, "%[([%d]+)%]$")
    if len then
        if vartype ~= "mchar" then
            return nil
        end
        t.name = string.sub(varname, 1, from - 1)
        t.len = tonumber(len)
        if t.len <= 1 then
            return nil
        end
        t.type_in_mysql = types[vartype .. "arry"]
    else
        t.name = varname
    end
    if string.sub(varname, 1, 3) == "m_d" then
        t.type_in_mysql = "timestamp"
    end
    t.splitted_name = split_fieldname(t.name)
    return t
end

local function parse_fields(def)
    local s = remove_comment_and_newline(def.fields)
    local r = {}
    for vartype, varname in string.gmatch(s, "([^%s]+)[%s]+([^%s]+)[%s]*;") do
        local t = parse_one_field(vartype, varname)
        if t then
            table.insert(r, t)
        else
            print("invalid field:", def.name, vartype, varname)
            parse_error = true
        end
    end
    return r
end

local function is_empty_table(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

local function parse_csv_line(text)
    local t = {}
    local s = text .. ","
    for name in string.gmatch(s, "([^%s,]+)[%s]*,") do
        table.insert(t, name)
    end
    return t
end

local function has_duplicate_field(t)
    local unique = {}
    for i, v in pairs(t) do
        if unique[v] then
            return true
        else
            unique[v] = 1
        end
    end
    return false
end

local function duplicate_with_pk(info, t)
    for i, v in pairs(t) do
        if info.pk[i] == nil then
            return false
        end
        if info.pk[i] ~= v then
            return false
        end
    end
    return true
end

local function parse_indexs(def)
    local r = {}
    for i, text in pairs(def.indexs) do
        local t = parse_csv_line(text)
        if not is_empty_table(t) then
            table.insert(r, t)
        end
    end
    return r
end

local function parse_pk(def)
    return parse_csv_line(def.pk)
end

local function optimize_index(info)
    if not cfg.index_optimize then
        return
    end
    local optimized = {}
    for i, index in pairs(info.indexs) do
        if not duplicate_with_pk(info, index) then
            table.insert(optimized, index)
        end
    end
    info.indexs = optimized
end

local function check_validation(info)
    local unique_fields = {}
    -- fields
    for i, field in pairs(info.fields) do
        if unique_fields[field.name] then
            print("duplicate field:", info.name, field.name)
            parse_error = true
        else
            unique_fields[field.name] = true
        end
    end
    -- indexs
    local unique_index = {}
    for i, index in pairs(info.indexs) do
        local s = table.concat(index, ",")
        if unique_index[s] then
            print("duplicate index:", info.name, s)
            parse_error = true
        else
            unique_index[s] = true
        end
        if has_duplicate_field(index) then
            print("index has duplicate field:", info.name, s)
            parse_error = true
        end
        for j, name in pairs(index) do
            if unique_fields[name] == nil then
                print("index has invalid field:", info.name, name)
                parse_error =  true
            end
        end
    end
    -- pk
    if has_duplicate_field(info.pk) then
        print("pk has duplicate field:", info.name, table.concat(info.pk, ","))
        parse_error = true
    end
    for i, name in pairs(info.pk) do
        if unique_fields[name] == nil then
            print("pk has invalid field:", info.name, name)
            parse_error = true
        end
    end
end

local function parse_tablename_in_sdl(name)
    return "S" .. string.sub(name, 2, -1)
end

local function parse_table_info()
    local unique_tables = {}
    for i, def in pairs(table_def) do
        local info = {}
        info.name = trim(def.name)
        info.name_in_sdl = parse_tablename_in_sdl(info.name)
        info.mysql_tablename = cfg.db_name .. "." .. def.name
        info.ori_fields = def.fields
        info.fields = parse_fields(def)
        info.indexs = parse_indexs(def)
        info.pk = parse_pk(def)
        info.no_syncup = def.no_syncup
        if unique_tables[info.name] then
            print("duplicate table:", info.name)
            parse_error = true
        else
            unique_tables[info.name] = 1
        end
        check_validation(info)
        optimize_index(info)
        table.insert(table_info, info)
    end
end

local function format_fields(info)
    local t = {}
    table.insert(t, " public:")
    for i, v in pairs(info.fields) do
        if v.len then
            table.insert(t, string.format("    mdb::%s %s[%d];", v.type, v.name, v.len))
        else
            table.insert(t, string.format("    mdb::%s %s;", v.type, v.name))
        end
    end
    return table.concat(t, "\n")
end

local function format_functions(info)
    local t = {}
    table.insert(t, " public:")
    -- construct
    table.insert(t, string.format([[
    %s() {
        Clear();
    }]], info.name))
    -- destruct
    table.insert(t, "")
    table.insert(t, string.format([[
    ~%s() {
    }]], info.name))
    -- Clear()
    table.insert(t, "")
    table.insert(t, [[
    void Clear() {
        memset(this, 0, sizeof(*this));
    }]])
    -- FromRow()
    table.insert(t, "")
    table.insert(t, "    void FromRow(const mdb::CMDBCursor& cur) {")
    for i, v in pairs(info.fields) do
        local s = ""
        -- getStrValue("imsi", imsi, 16);
        -- acct_id = cur.getFieldValue<mdb::mint8>("acct_id");
        if v.len then
            s = string.format("        cur.getStrValue(\"%s\", %s, %d);", v.name, v.name, v.len)
        else
            s = string.format("        %s = cur.getFieldValue<mdb::%s>(\"%s\");", v.name, v.type, v.name)
        end
        table.insert(t, s)
    end
    table.insert(t, "    }")
    -- ToRow()
    table.insert(t, "")
    table.insert(t, "    void ToRow(mdb::CMDBCursor& cur) {")
    for i, v in pairs(info.fields) do
        local s = ""
        -- cur.setFieldValue<mdb::mint8>("acct_id", acct_id);
        -- cur.setFieldValue<const mdb::mchar*>("imsi", imsi, 16);
        if v.len then
            s = string.format("        cur.setFieldValue<const mdb::%s*>(\"%s\", %s, %d);", v.type, v.name, v.name, v.len)
        else
            s = string.format("        cur.setFieldValue<mdb::%s>(\"%s\", %s);", v.type, v.name, v.name)
        end
        table.insert(t, s)
    end
    table.insert(t, "    }")
    return table.concat(t, "\n")
end

local function format_class(info)
    local fields = format_fields(info)
    local functions = format_functions(info)
    return string.format([[
class %s {
%s

%s
};
]], info.name, fields, functions)
end

local function gencpp_table()
    local filehead = string.format([[
// %s

#ifndef %s
#define %s

#include <string.h>  // for memset()
#include <mysql/mdb/mdb_cursor.h>

namespace %s {
]], cfg.autogen_info, cfg.cpp_headfile_guard, cfg.cpp_headfile_guard, cfg.namespace)

    local filetail = string.format([[
}  // namespace %s

#endif  // %s
]], cfg.namespace, cfg.cpp_headfile_guard)

    local t = {}
    table.insert(t, filehead)
    for i, info in pairs(table_info) do
        table.insert(t, format_class(info))
    end
    table.insert(t, filetail)

    local text = table.concat(t, "\n")
    local filename = cfg.cpp_headfile
    local fd = io.open(filename, "w+")
    fd:write(text)
    fd:close()
end

local function format_table_fields(info)
    local t = {}
    for i, v in pairs(info.fields) do
        local s = ""
        if v.len then
            s = string.format("    %s %s(%d) CHARSET latin1 NOT NULL", v.name, string.upper(v.type_in_mysql), v.len - 1)
        else
            if v.type_in_mysql == "timestamp" then
                s = string.format("    %s %s NOT NULL DEFAULT CURRENT_TIMESTAMP", v.name, string.upper(v.type_in_mysql))
            else
                s = string.format("    %s %s NOT NULL", v.name, string.upper(v.type_in_mysql))
            end
        end
        table.insert(t, s)
    end
    return table.concat(t, ",\n")
end

local function format_table(info)
    local t = {}
    local tablename = info.mysql_tablename
    local table_fields = format_table_fields(info)
    return string.format([[
DROP TABLE IF EXISTS %s;
CREATE TABLE %s (
%s
) ENGINE=MDB MIN_ROWS=10000 DEFAULT CHARSET=utf8;
]], tablename, tablename, table_fields)
end

local function gensql_create()
    local t = {}
    table.insert(t, string.format("-- %s", cfg.autogen_info))
    table.insert(t, "")
    table.insert(t, "-- create database")
    table.insert(t, string.format("CREATE DATABASE IF NOT EXISTS %s;", cfg.db_name))
    table.insert(t, "")
    table.insert(t, "-- create tables")
    for i, info in pairs(table_info) do
        table.insert(t, format_table(info))
    end

    local text = table.concat(t, "\n")
    local filename = cfg.sql_createfile
    local fd = io.open(filename, "w+")
    fd:write(text)
    fd:close()
end

local function format_indexs(info)
    local t = {}
    for i, v in pairs(info.indexs) do
        local index_name = "IDX" .. i
        local s = string.format("ALTER TABLE %s ADD INDEX %s (%s);", info.mysql_tablename, index_name, table.concat(v, ", "))
        table.insert(t, s)
    end
    return table.concat(t, "\n")
end

local function gensql_constraint()
    local t = {}
    table.insert(t, string.format("-- %s", cfg.autogen_info))
    table.insert(t, "")
    for i, info in pairs(table_info) do
        local comment = string.format("-- %s", info.mysql_tablename)
        local pk = string.format("ALTER TABLE %s ADD PRIMARY KEY (%s);", info.mysql_tablename, table.concat(info.pk, ", "))
        local indexs = format_indexs(info)
        table.insert(t, comment)
        table.insert(t, pk)
        if indexs ~= "" then
            table.insert(t, indexs)
        end
        table.insert(t, "")
    end

    local text = table.concat(t, "\n")
    local filename = cfg.sql_constraintfile
    local fd = io.open(filename, "w+")
    fd:write(text)
    fd:close()
end

local function gensql()
    gensql_create()
    gensql_constraint()
end

local function format_sdlfields(info)
    local t = {}
    for i, field in pairs(info.fields) do
        table.insert(t, string.format("    %s;", table.concat(field.splitted_name, "_")))
    end
    return table.concat(t, "\n")
end

local function find_field(info, name)
    for i, field in pairs(info.fields) do
        if name == field.name then
            return field
        end
    end
end

local function get_sdl_getter_name(field)
    local s = "get_"
    for i, v in pairs(field.splitted_name) do
        if i == 1 then
            s = s .. v
        else
            s = s .. string.upper(string.sub(v, 1, 1)) .. string.sub(v, 2, -1)
        end
    end
    return s
end

local function format_syncup_func_decl(info)
    local t = {}
    table.insert(t, "")
    table.insert(t, string.format("    // table: %s, sdl: %s", info.name, info.name_in_sdl))
    -- IsKeyEqual()
    table.insert(t, string.format("    static bool IsKeyEqual(const %s& obj, const mdb::CMDBCursor& cur);", info.name_in_sdl))
    -- SdlToRow()
    table.insert(t, string.format("    static void SdlToRow(const %s& obj, mdb::CMDBCursor& cur);", info.name_in_sdl))
    -- SdlUpdateRow()
    table.insert(t, string.format("    static void SdlUpdateRow(const %s& obj, mdb::CMDBCursor& cur);", info.name_in_sdl))
    return table.concat(t, "\n")
end

local function format_syncup_func(info)
    local t = {}
    table.insert(t, "")
    table.insert(t, string.format("// table: %s, sdl: %s", info.name, info.name_in_sdl))
    -- IsKeyEqual()
    table.insert(t, string.format("bool SyncUp::IsKeyEqual(const %s& obj, const mdb::CMDBCursor& cur) {", info.name_in_sdl))
    for i, name in pairs(info.pk) do
        local field = find_field(info, name)
        if field then
            local sdl_getter_name = get_sdl_getter_name(field)
            if field.len then
                table.insert(t, string.format([[
    mdb::mchar %s[%d] = {0};
    cur.getStrValue("%s", %s, %d);
    if (strcmp(%s, obj.%s().c_str()) != 0) {
        return false;
    }]], field.name, field.len, field.name, field.name, field.len, field.name, sdl_getter_name))
            else
                table.insert(t, string.format([[
    if (obj.%s() != cur.getFieldValue<mdb::%s>("%s")) {
        return false;
    }]], sdl_getter_name, field.type, field.name))
            end
        end
    end
    table.insert(t, "    return true;")
    table.insert(t, "}")
    -- SdlToRow()
    table.insert(t, string.format("void SyncUp::SdlToRow(const %s& obj, mdb::CMDBCursor& cur) {", info.name_in_sdl))
    for i, field in pairs(info.fields) do
        local sdl_getter_name = get_sdl_getter_name(field)
        if field.len then
            table.insert(t, string.format([[
    cur.setFieldValue<const mdb::%s*>("%s", obj.%s().c_str(), obj.%s().size());]], field.type, field.name, sdl_getter_name, sdl_getter_name))
        else
            table.insert(t, string.format([[
    cur.setFieldValue<mdb::%s>("%s", obj.%s());]], field.type, field.name, sdl_getter_name))
        end
    end
    table.insert(t, "}")
    return table.concat(t, "\n")
end

local function gencpp_syncup()
    local filehead = string.format([[
// %s

#include "user_mdb_syncup_autogen.h"
#include "user_mdb_syncup_def_sdl_c.h"
#include <mysql/mdb/mdb_cursor.h>
#include <string.h>  // for strcmp()

using namespace MMdbSyncUpDef;

namespace %s {]], cfg.autogen_info, cfg.namespace)
    local filetail = string.format([[

}  // namespace %s
]], cfg.namespace)

    local t = {}
    table.insert(t, filehead)
    for i, info in pairs(table_info) do
        if not info.no_syncup then
            table.insert(t, format_syncup_func(info))
        end
    end
    table.insert(t, filetail)

    local text = table.concat(t, "\n")
    local filename = "user_mdb_syncup_autogen.cpp"
    local fd = io.open(filename, "r")
    if fd then
        fd:close()
        print(string.format("file already exists! skip. (%s)", filename))
        return
    end
    local fd = io.open(filename, "w+")
    fd:write(text)
    fd:close()
end

local function gencpp_syncup_h()
    local filehead = string.format([[
// %s

#ifndef _USER_MDB_SYNCUP_AUTOGEN_H_
#define _USER_MDB_SYNCUP_AUTOGEN_H_

#include "user_mdb_syncup_def_sdl_c.h"
#include <mysql/mdb/mdb_cursor.h>

using namespace MMdbSyncUpDef;

namespace %s {

class SyncUp {
 public:]], cfg.autogen_info, cfg.namespace)

    local filetail = string.format([[
};

}  // namespace %s

#endif  // _USER_MDB_SYNCUP_AUTOGEN_H_
]], cfg.namespace)

    local t = {}
    table.insert(t, filehead)
    for i, info in pairs(table_info) do
        if not info.no_syncup then
            table.insert(t, format_syncup_func_decl(info))
        end
    end
    table.insert(t, filetail)

    local text = table.concat(t, "\n")
    local filename = "user_mdb_syncup_autogen.h"
    local fd = io.open(filename, "w+")
    fd:write(text)
    fd:close()
end

local function gencode()
    gencpp_table()
    gencpp_syncup_h()
    gencpp_syncup()
    gensql()
end

local function run()
    init()
    parse_table_info()
    if parse_error then
        return -1
    end
    gencode()
end

run()
