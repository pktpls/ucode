const c = require("ctypes");
const struct = require("struct");

const sizeof = (abbreviation) => length(struct.pack(abbreviation));

const abbreviation_to_ffi = {
  i: c.ffi_type.sint,
  P: c.ffi_type.pointer,
  N: c.ffi_type["uint" + sizeof("N") * 8],
};

function attach(dl_handle, fun) {
  const params_list = split(fun.params, "");
  const cif = c.prep(
    c.const.FFI_DEFAULT_ABI,
    ...map(params_list, (a) => abbreviation_to_ffi[a])
  );
  return function (...args) {
    // printf("args: %J\n", args);
    const packed = struct.pack(fun.params, 0, ...args);
    const return_buffer = c.ptr(packed);
    const s = c.symbol(dl_handle, fun.name);
    assert(s != null);
    assert(cif.call(s, return_buffer));
    return struct.unpack(
      substr(fun.params, 0, 1),
      return_buffer.ucv_string_new()
    )[0];
  };
}

const libc = {};
for (fun in [
  { name: "dlopen", params: "PPi" },
  { name: "strlen", params: "NP" },
]) {
  libc[fun.name] = attach(c.const.RTLD_DEFAULT, fun);
}

function dlopen(library_name) {
  const library_name_copy = c.ptr(library_name);
  const return_ptr = libc.dlopen(library_name_copy.as_int(), c.const.RTLD_NOW);
  assert(library_name_copy.drop());
  assert(return_ptr != 0);
  return c.ptr(return_ptr);
}

const libsqlite = {
  const: {
    SQLITE_OK: 0,
    SQLITE_DONE: 101,
    SQLITE_DBSTATUS_CACHE_USED: 1,
    SQLITE_DBSTATUS_SCHEMA_USED: 2,
  }
};
for (fun in [
  { name: "sqlite3_errstr", params: "Pi" },
  { name: "sqlite3_exec", params: "iPPPPP" },
  { name: "sqlite3_libversion", params: "P" },
  { name: "sqlite3_open", params: "iPP" },
  { name: "sqlite3_db_status", params: "iPiPPi" },
]) {
  libsqlite[fun.name] = attach(dlopen("libsqlite3.so.0"), fun);
}

// const char *sqlite3_errstr(int);
function sqlite_errstr(code) {
  assert(code != null);
  let return_ptr = libsqlite.sqlite3_errstr(code);
  let len = libc.strlen(return_ptr);
  return c.ptr(return_ptr).ucv_string_new(len);
}

// const char *sqlite3_libversion(void);
function sqlite_version() {
  let return_ptr = libsqlite.sqlite3_libversion();
  let len = libc.strlen(return_ptr);
  return c.ptr(return_ptr).ucv_string_new(len);
}

// int sqlite3_open(const char *filename, sqlite3 **ppDb);
function sqlite_open(db_ptr, file) {
  let file_ptr = c.ptr(file);
  let ret = libsqlite.sqlite3_open(file_ptr.as_int(), db_ptr.as_int());
  assert(ret == libsqlite.const.SQLITE_OK, sprintf("sqlite_open failed: code=%d", ret));
  return { ptr: db_ptr.as_int(), file: file };
}

// int sqlite3_db_status(sqlite3*, int op, int *pCur, int *pHiwtr, int resetFlg);
function sqlite_db_status(db) {
  let cur_ptr = c.ptr(struct.pack("i"));
  let hiw_ptr = c.ptr(struct.pack("i"));

  // XXX db.ptr is still a sqlite3**, we need sqlite3*
  let ret = libsqlite.sqlite3_db_status(db.ptr, libsqlite.const.SQLITE_DBSTATUS_SCHEMA_USED,
                                        cur_ptr.as_int(), hiw_ptr.as_int(), 0);
  assert(ret == libsqlite.const.SQLITE_OK, sprintf("sqlite_db_status failed: code=%d", ret));

  let su_cur_arr = struct.unpack("i", cur_ptr.ucv_string_new());
  return { schema_used: { current: su_cur_arr[0] } };
}

// int sqlite3_exec(sqlite3*, const char *sql, int (*callback)(void*,int,char**,char**) void *, char **errmsg);
function sqlite_exec(db, sql) {
  printf("sql: %J\n", sql);
  let sql_ptr = c.ptr(sql);
  // XXX db.ptr is still a sqlite3**, we need sqlite3*
  let ret = libsqlite.sqlite3_exec(db.ptr, sql_ptr.as_int(), null, null, null);
  assert(ret == libsqlite.const.SQLITE_OK,
         sprintf("sqlite_exec failed: code=%d errmsg=%J", ret, sqlite_errstr(ret)));

  return ret;
}

print("sqlite version: ", sqlite_version(), "\n");

// poor man's pointer-to-a-pointer
let db_ptr = c.ptr(struct.pack("8x8x8x8x8x8x8x8x"));
let db = sqlite_open(db_ptr, ":memory:");
printf("db: %J\n", db);

printf("status: %J\n", sqlite_db_status(db));

sqlite_exec(db, "CREATE TABLE foo (name VARCHAR(255), value VARCHAR(255));");
sqlite_exec(db, "INSERT INTO foo SET name = 'foo', value = 'bar';");
sqlite_exec(db, "INSERT INTO foo SET name = 'fuu', value = 'baz';");
printf("select: %J\n", sqlite_exec(db, "SELECT * FROM foo;"));

// function my_cb_func(arg) {
//   printf("cb: %J\n");
//   return 0;
// }

// function noop_with_cb(cb) {
//   // const cb_ptr = c.cb(cb);
//   const cb_ptr = c.ptr(123);
//   const msg = "hello";
//   const msg_ptr = c.ptr(msg);
//   libc.ctypes_noop_with_cb(cb_ptr.as_int(), msg_ptr.as_int());
// }

// noop_with_cb(my_cb_func);
