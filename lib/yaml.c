
#include <libfyaml.h>

#include "ucode/module.h"
#include "ucode/platform.h"

static uc_value_t *
ucv_from_fyaml(uc_vm_t *vm, struct fy_node *fyn)
{
  uc_value_t *uv;
  void *iter;
  int len, i = 0;
  struct fy_node *fysn;
  struct fy_node_pair *fynp;

  switch (fy_node_get_type(fyn)) {
  case FYNT_SCALAR:
    return ucv_string_new_length(fy_node_get_scalar0(fyn), fy_node_get_scalar_length(fyn));
  case FYNT_MAPPING:
    uv = ucv_object_new(vm);
    iter = NULL;
    len = fy_node_mapping_item_count(fyn);
    while (i < len) {
      fynp = fy_node_mapping_iterate(fyn, &iter);
      ucv_object_add(uv, fy_node_get_scalar0(fy_node_pair_key(fynp)),
                     ucv_from_fyaml(vm, fy_node_pair_value(fynp)));
      i++;
    }
    return uv;
  case FYNT_SEQUENCE:
    uv = ucv_array_new(vm);
    iter = NULL;
    len = fy_node_sequence_item_count(fyn);
    while (i < len) {
      fysn = fy_node_sequence_iterate(fyn, &iter);
      ucv_array_push(uv, ucv_from_fyaml(vm, fysn));
      i++;
    }
    return uv;
  default:
    uc_vm_raise_exception(vm, EXCEPTION_TYPE,
                          "Passed YAML node is neither a mapping nor a scalar value");
  }

  return NULL;
}

static uc_value_t *
uc_yaml(uc_vm_t *vm, size_t nargs)
{
  uc_value_t *rv = NULL, *src = uc_fn_arg(0);
  struct fy_document *fyd;
  struct fy_node *fyn;

  switch (ucv_type(src)) {
  case UC_STRING:
    fyd = fy_document_build_from_string(NULL, ucv_string_get(src),
                                        ucv_string_length(src));
    if (!fyd)
      uc_vm_raise_exception(vm, EXCEPTION_SYNTAX,
                            "Failed to parse YAML document");
    break;
  default:
    uc_vm_raise_exception(vm, EXCEPTION_TYPE,
                          "Passed value is not a string");
  }

  if (!fyd)
    goto out;

  fyn = fy_document_root(fyd);
  rv = ucv_from_fyaml(vm, fyn);

out:
  if (fyd)
    fy_document_destroy(fyd);

  return rv;
}

static const uc_function_list_t global_fns[] = {
  { "yaml", uc_yaml },
};

void uc_module_init(uc_vm_t *vm, uc_value_t *scope)
{
  uc_function_list_register(scope, global_fns);
}
