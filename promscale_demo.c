#include <promscale_demo.h>

PG_MODULE_MAGIC;

Datum tag_map_support(PG_FUNCTION_ARGS);


PG_FUNCTION_INFO_V1(tag_map_support);

Datum
tag_map_support(PG_FUNCTION_ARGS)
{
	Node	   *rawreq = (Node *) PG_GETARG_POINTER(0);
	Node	   *ret = NULL;

	if (IsA(rawreq, SupportRequestSimplify))
	{
		SupportRequestSimplify *req = (SupportRequestSimplify *) rawreq;

		if (req->root == NULL)
		{
			PG_RETURN_POINTER(NULL);
		}
		else /* Solely to suppress warning about mixed declarations and code */
		{
			FuncExpr   *eqFunc = req->fcall;
			Node *eqOpArgLeft  = linitial(eqFunc->args); /* arrow func */
			Node *eqOpArgRight = lsecond (eqFunc->args); /* jsonb value */

			// elog_node_display(WARNING, "Expr node", expr, true);

			if (IsA(eqOpArgLeft, OpExpr))
			{
				OpExpr *arrowOp = (OpExpr *) eqOpArgLeft;
				char *arrowOpName = get_opname(arrowOp->opno);
				if (strcmp(arrowOpName, "->") == 0)
				{
					/* TODO?: be super paranoid and check argtype to be tag_map */

					Node *arrowOpArgLeft  = linitial(arrowOp->args); /* Denormalize func */
					Node *arrowOpArgRight = lsecond (arrowOp->args); /* Label text */

					// elog_node_display(WARNING, "arrowOpArgLeft node", arrowOpArgLeft, true);

					if (IsA(arrowOpArgLeft, FuncExpr))
					{
						FuncExpr *denormalizeFunc = (FuncExpr *) arrowOpArgLeft;
						char *denormalizeFuncName = get_func_name(denormalizeFunc->funcid);

						if (strcmp(denormalizeFuncName, DENORMALIZE_FUNC_NAME) == 0)
						{
							/* Get what would be our target column */
							Node 		*denormalizeFuncArg  = linitial(denormalizeFunc->args);
							FuncExpr    *containsExpr;
							FuncExpr    *findLabelsExpr;
							FuncDetailCode fdContains;
							Oid			jsonbContainsFuncOID;
							Oid			findLabelsFuncOID;
							Oid			jsonbContainsFuncRetTypeOID;
							Oid			findLabelsFuncRetTypeOID;
							bool		p_retset;
							int			p_nvargs;
							Oid			p_vatype;
							Oid		   *p_true_typeids;
							/* make a list of arguments for find_label_ids func */
							List *findLabelFuncArgs = list_make2(arrowOpArgRight, eqOpArgRight);
							List *containsFuncArgs;
							// List *argnames = list_make2();
							Oid jsonbContainsFuncArgTypes[] = {JSONBOID, JSONBOID};
							Oid findLabelsFuncArgTypes[]    = {TEXTOID,  JSONBOID};

							fdContains = func_get_detail(list_make2(
										makeString(SCHEMA_PG_CATALOG),
										makeString(JSONB_CONTAINS_FUNC_NAME)),
													NIL, NIL, 2, jsonbContainsFuncArgTypes,
													false, false, false,
													&jsonbContainsFuncOID, &jsonbContainsFuncRetTypeOID,
													&p_retset, &p_nvargs, &p_vatype,
													&p_true_typeids, NULL);

							if (fdContains != FUNCDETAIL_NORMAL)
								elog(ERROR, "Something is wrong with \"%s\" function", JSONB_CONTAINS_FUNC_NAME);

							fdContains = func_get_detail(list_make2(
										makeString(SCHEMA_PS_TRACE_INTERNAL),
										makeString(FIND_LABELS_FUNC_NAME)),
													NIL, NIL, 2, findLabelsFuncArgTypes,
													false, false, false,
													&findLabelsFuncOID, &findLabelsFuncRetTypeOID,
													&p_retset, &p_nvargs, &p_vatype,
													&p_true_typeids, NULL);

							if (fdContains != FUNCDETAIL_NORMAL)
								elog(ERROR, "Something is wrong with \"%s\" function", FIND_LABELS_FUNC_NAME);

							findLabelsExpr = makeFuncExpr(findLabelsFuncOID, findLabelsFuncRetTypeOID,
								findLabelFuncArgs, fcinfo->fncollation,
								fcinfo->fncollation, COERCE_EXPLICIT_CALL);

							containsFuncArgs = list_make2(denormalizeFuncArg, findLabelsExpr);

							containsExpr = makeFuncExpr(jsonbContainsFuncOID, jsonbContainsFuncRetTypeOID,
								containsFuncArgs, fcinfo->fncollation,
								fcinfo->fncollation, COERCE_EXPLICIT_CALL);

							// Expr *new = make_orclause(quals);
							// new = eval_const_expressions(req->root, new);
							PG_RETURN_POINTER(containsExpr);
						}
					}
				}
			}
		}

	}

	PG_RETURN_POINTER(ret);
}


