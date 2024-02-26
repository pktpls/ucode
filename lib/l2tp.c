
#include <stdio.h>

#include "ucode/module.h"

#define err_return(code, ...) do { set_error(code, __VA_ARGS__); return NULL; } while(0)

static struct {
  int code;
  char *msg;
} last_error;

__attribute__((format(printf, 2, 3))) static void
set_error(int errcode, const char *fmt, ...) {
  va_list ap;

  free(last_error.msg);

  last_error.code = errcode;
  last_error.msg = NULL;

  if (fmt) {
    va_start(ap, fmt);
    xvasprintf(&last_error.msg, fmt, ap);
    va_end(ap);
  }
}

static const uc_l2tp_nested_spec_t l2tp_tunnel_create_msg = {
  .headsize = 0,
  .nattrs = 5,
  .attrs = {
    { L2TP_ATTR_PROTO_VERSION, "proto_version", DT_, 0, NULL },
    { L2TP_ATTR_CONN_ID, "conn_id", DT_, 0, NULL },
    { L2TP_ATTR_PEER_CONN_ID, "peer_conn_id", DT_, 0, NULL },
    { L2TP_ATTR_ENCAP_TYPE, "encap_type", DT_, 0, NULL },
    { L2TP_ATTR_FD, "fd", DT_, 0, NULL },
  }
};

static const uc_l2tp_nested_spec_t l2tp_tunnel_delete_msg = {
  .headsize = 0,
  .nattrs = 2,
  .attrs = {
    { L2TP_ATTR_CONN_ID, "conn_id", DT_, 0, NULL },
    { L2TP_ATTR_SESSION_ID, "session_id", DT_, 0, NULL },
  }
};
static const uc_l2tp_nested_spec_t l2tp_session_create_msg = {
  .headsize = 0,
  .nattrs = 5,
  .attrs = {
    { L2TP_ATTR_CONN_ID, "conn_id", DT_, 0, NULL },
    { L2TP_ATTR_SESSION_ID, "session_id", DT_, 0, NULL },
    { L2TP_ATTR_PEER_SESSION_ID, "peer_session_id", DT_, 0, NULL },
    { L2TP_ATTR_PW_TYPE, "pw_type", DT_, 0, NULL },
    { L2TP_ATTR_IFNAME, "ifname", DT_, 0, NULL },
  }
};
static const uc_l2tp_nested_spec_t l2tp_session_delete_msg = {
  .headsize = 0,
  .nattrs = 1,
  .attrs = {
    { L2TP_ATTR_CONN_ID, "conn_id", DT_, 0, NULL },
  }
};
static const uc_l2tp_nested_spec_t l2tp_session_set_mtu_msg = {
  .headsize = 0,
  .nattrs = 3,
  .attrs = {
    { L2TP_ATTR_CONN_ID, "conn_id", DT_, 0, NULL },
    { L2TP_ATTR_SESSION_ID, "session_id", DT_, 0, NULL },
    { L2TP_ATTR_MTU, "mtu", DT_, 0, NULL },
  }
};



static void
register_constants(uc_vm_t *vm, uc_value_t *scope)
{
  uc_value_t *c = ucv_object_new(vm);

  ucv_object_add(c, "WG_GENL_NAME", ucv_string_new_length("wireguard", 9));
  ucv_object_add(c, "WG_GENL_VERSION", ucv_uint64_new(1));

#define ADD_CONST(x) ucv_object_add(c, #x, ucv_int64_new(x))

  ADD_CONST(NLM_F_DUMP);

  ucv_object_add(scope, "const", c);
};

static const uc_function_list_t global_fns[] = {
  { "error",    uc_l2tp_error },
  { "request",  uc_l2tp_request },
};

void uc_module_init(uc_vm_t *vm, uc_value_t *scope)
{
  uc_function_list_register(scope, global_fns);

  register_constants(vm, scope);
}
