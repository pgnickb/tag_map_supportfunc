#ifndef PROMSCALE_DEMO_H
#define PROMSCALE_DEMO_H

#include "postgres.h"
#include "access/attnum.h"
#include "access/printtup.h"
#include "catalog/namespace.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "lib/stringinfo.h"
#include "nodes/bitmapset.h"
#include "nodes/execnodes.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "nodes/nodes.h"
#include "nodes/pathnodes.h"
#include "nodes/pg_list.h"
#include "nodes/print.h"
#include "nodes/supportnodes.h"
#include "optimizer/optimizer.h"
#include "parser/parse_func.h"
#include "parser/parse_node.h"
#include "parser/parse_oper.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/json.h"
#include "utils/jsonb.h"
#include "utils/jsonfuncs.h"
#include "utils/lsyscache.h"
#include "utils/selfuncs.h"
#include "utils/syscache.h"
#include "utils/typcache.h"

PG_MODULE_MAGIC;
Datum tag_map_support(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(tag_map_support);

#define SCHEMA_PG_CATALOG           "pg_catalog"
#define SCHEMA_PS_TRACE_INTERNAL    "_ps_trace"
#define SCHEMA_PS_TRACE             "ps_trace"

#define DENORMALIZE_FUNC_NAME       "tag_map_denormalize"
#define FIND_LABELS_FUNC_NAME       "find_label_ids"
#define JSONB_CONTAINS_FUNC_NAME    "jsonb_contains"
#define JSONB_CONTAINS_OP_NAME      "@>"

#define RAISE_ERROR_IF_NOT_FOUND    true

#endif /* PROMSCALE_DEMO_H */
