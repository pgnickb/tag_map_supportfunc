#include <promscale_demo.h>

Datum
tag_map_support(PG_FUNCTION_ARGS)
{
    Node        *rawreq = (Node *) PG_GETARG_POINTER(0);
    Node        *ret = NULL;

    if (IsA(rawreq, SupportRequestSimplify))
    {
        SupportRequestSimplify *req = (SupportRequestSimplify *) rawreq;

        if (req->root == NULL)
        {
            PG_RETURN_POINTER(NULL);
        }
        else /* Solely to suppress warning about mixed declarations and code */
        {
            FuncExpr *eqFunc = req->fcall;
            Node *eqOpArgLeft  = linitial(eqFunc->args); /* arrow func */
            Node *eqOpArgRight = lsecond (eqFunc->args); /* jsonb value */

            elog_node_display(DEBUG1, "Original root", eqFunc, true);

            if (IsA(eqOpArgLeft, OpExpr))
            {
                OpExpr *arrowOp = (OpExpr *) eqOpArgLeft;
                char *arrowOpName = get_opname(arrowOp->opno);
                if (strcmp(arrowOpName, "->") == 0)
                {
                    /* TODO?: be super paranoid and check argtype to be tag_map */

                    Node *arrowOpArgLeft  = linitial(arrowOp->args); /* Denormalize func */
                    Node *arrowOpArgRight = lsecond (arrowOp->args); /* Label text */

                    if (IsA(arrowOpArgLeft, FuncExpr))
                    {
                        FuncExpr *denormalizeFunc = (FuncExpr *) arrowOpArgLeft;
                        char *denormalizeFuncName = get_func_name(denormalizeFunc->funcid);

                        if (strcmp(denormalizeFuncName, DENORMALIZE_FUNC_NAME) == 0)
                        {
                            /* We're all set. Build the new execution plan: */
                            /* Get what would be our target column */
                            Node        *denormalizeFuncArg = linitial(denormalizeFunc->args);
                            Expr        *containsOpExpr;
                            FuncExpr    *findLabelsExpr;
                            FuncDetailCode fd;
                            Oid         jsonbContainsOpOID;
                            Oid         findLabelsFuncOID;
                            Oid         findLabelsFuncRetTypeOID;
                            bool        p_retset;
                            int         p_nvargs;
                            Oid         p_vatype;
                            Oid         *p_true_typeids;
                            /* Make a list of arguments for find_label_ids func */
                            List *findLabelFuncArgs = list_make2(arrowOpArgRight, eqOpArgRight);
                            Oid findLabelsFuncArgTypes[] = {TEXTOID,  JSONBOID};

                            /* Locate the find_label_ids function */
                            fd = func_get_detail(list_make2(
                                        makeString(SCHEMA_PS_TRACE_INTERNAL),
                                        makeString(FIND_LABELS_FUNC_NAME)),
                                                    NIL, NIL, 2, findLabelsFuncArgTypes,
                                                    false, false, false,
                                                    &findLabelsFuncOID, &findLabelsFuncRetTypeOID,
                                                    &p_retset, &p_nvargs, &p_vatype,
                                                    &p_true_typeids, NULL);

                            if (fd != FUNCDETAIL_NORMAL)
                                elog(ERROR, "Something is wrong with \"%s\" function", FIND_LABELS_FUNC_NAME);

                            /* Locate @> jsonb operator */
                            jsonbContainsOpOID = LookupOperName(NULL, list_make2(
                                    makeString(SCHEMA_PG_CATALOG),
                                    makeString(JSONB_CONTAINS_OP_NAME)), JSONBOID, JSONBOID,
                                  RAISE_ERROR_IF_NOT_FOUND, -1);

                            /* Make a planner node for a function call */
                            findLabelsExpr = makeFuncExpr(findLabelsFuncOID, findLabelsFuncRetTypeOID,
                                findLabelFuncArgs, fcinfo->fncollation,
                                fcinfo->fncollation, COERCE_EXPLICIT_CALL);

                            /* Make a planner node for the operator (this is our new root) */
                            containsOpExpr = make_opclause(jsonbContainsOpOID, BOOLOID, false,
                                (Expr *) denormalizeFuncArg, (Expr *) findLabelsExpr, fcinfo->fncollation,
                                fcinfo->fncollation);

                            elog_node_display(DEBUG1, "New root", containsOpExpr, true);

                            PG_RETURN_POINTER(containsOpExpr);
                        }
                    }
                }
            }
        }

    }

    PG_RETURN_POINTER(ret);
}


