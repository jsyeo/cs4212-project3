open Arm_structs

open Ir3_structs

open Jlite_structs

open Printf

(*
Every ir3 language construct is converted into a pair of instruction lists.
One containing the data section, another containing the instructions.
*)

(*
HOF that makes fresh (labels|vars|regs|fruits) generators for DRY-ness.
The prefix is the string in the identifier.
e.g
let fresh_orange = fresh_maker "orange";;
fresh_orange() => "orange1"
fresh_orange() => "orange2";;
*)
let fresh_maker prefix =
    let count = ref 0 in
    (fun () ->
     count := !count + 1;
     prefix ^ string_of_int !count)

let fresh_label = fresh_maker "L"

let fresh_arg_reg = fresh_maker "a"

let fresh_reg_var = fresh_maker "v"

let idc3_to_arm_literal (idc:idc3)
  : (arm_instr list * arm_instr list * string) =
  match idc with
  | StringLiteral3 s ->
     let l = fresh_label() in
     ([Label l; PseudoInstr (sprintf ".asciz \"%s\"" s)],[],l)
  | IntLiteral3 i ->
     (* TODO: JS *)
     let frv = fresh_reg_var() in
     ([],[MOV ("", false, frv, ImmedOp (string_of_int i))],frv)
  | BoolLiteral3 b ->
     (* TODO: JS *)
     failwith "Unhandled idc3: BoolLiteral3"
  | Var3 id3 ->
     (* TODO: JS *)
     failwith "Unhandled idc3: Var3"

let ir3_exp_to_arm ir3exp =
  let rec aux ir3exp =
    match ir3exp with
    | BinaryExp3 (op, idc1, idc2) ->
       (* TODO: XY *)
       begin
        let (arm1data,arm1instr,reg1),(arm2data,arm2instr,reg2) = (idc3_to_arm_literal idc1),(idc3_to_arm_literal idc2) in
        let frv = fresh_reg_var() in
        (* TODO : If reg2 is a constant, use RSB instead *)
        let armexprinstr = match op with
        | AritmeticOp "+" ->
           [ADD ("", false, frv, reg1, RegOp reg2)]
        | AritmeticOp "-" ->
           [SUB ("", false, frv, reg1, RegOp reg2)]
        | AritmeticOp "*" ->
           [MUL ("", false, frv, reg1, reg2)]
		| RelationalOp "<" ->
		   (*
		   	cmp a4,a3
		    movlt v3,#1
		    movge v3,#0
		
		    (a4 < a3)
			*)
		   let cmpinstr = CMP ("", reg1, reg2) in
		   let movltinstr = MOV ("lt", false, frv, ImmedOp "#1") in
		   let movgeinstr = MOV ("ge", false, frv, ImmedOp "#0") in
		   [cmpinstr; movltinstr; movgeinstr]
		| RelationalOp "<=" ->
		   let cmpinstr = CMP ("", reg1, reg2) in
		   let movltinstr = MOV ("le", false, frv, ImmedOp "#1") in
		   let movgeinstr = MOV ("gt", false, frv, ImmedOp "#0") in
		   [cmpinstr; movltinstr; movgeinstr]
		|  RelationalOp ">" ->
		   let cmpinstr = CMP ("", reg1, reg2) in
		   let movltinstr = MOV ("gt", false, frv, ImmedOp "#1") in
		   let movgeinstr = MOV ("le", false, frv, ImmedOp "#0") in
		   [cmpinstr; movltinstr; movgeinstr]
		| RelationalOp ">=" ->
		   let cmpinstr = CMP ("", reg1, reg2) in
		   let movltinstr = MOV ("ge", false, frv, ImmedOp "#1") in
		   let movgeinstr = MOV ("lt", false, frv, ImmedOp "#0") in
		   [cmpinstr; movltinstr; movgeinstr]
		| RelationalOp "==" ->
		   let cmpinstr = CMP ("", reg1, reg2) in
		   let movltinstr = MOV ("eq", false, frv, ImmedOp "#1") in
		   let movgeinstr = MOV ("ne", false, frv, ImmedOp "#0") in
		   [cmpinstr; movltinstr; movgeinstr]
		| RelationalOp "!=" ->
		   let cmpinstr = CMP ("", reg1, reg2) in
		   let movltinstr = MOV ("ne", false, frv, ImmedOp "#1") in
		   let movgeinstr = MOV ("eq", false, frv, ImmedOp "#0") in
		   [cmpinstr; movltinstr; movgeinstr]
        | _ -> failwith "Unhandled ir3exp: BinaryExp3 (other types)"
        in
        (arm1data @ arm2data, arm1instr @ arm2instr @ armexprinstr, frv)
      end
    | UnaryExp3 (op, idc) ->
        (* TODO: XY *)
        begin
          let armdata, armistr, reg = idc3_to_arm_literal idc in
          let frv = fresh_reg_var() in
          let armexprinstr = match op with
          | UnaryOp "-" ->
             [RSB ("", false, frv, reg, ImmedOp "#0")]
          | UnaryOp "!" ->
             [RSB ("", false, frv, reg, ImmedOp "#1")]
        end
       failwith "Unhandled ir3exp: UnaryExp3"
    | FieldAccess3 (id1, id2) ->
       (* TODO: XY *)
       failwith "Unhandled ir3exp: FieldAccess3"
    | Idc3Expr idc ->
       (* TODO: XY *)
       failwith "Unhandled ir3exp: Idc3Expr"
    | MdCall3 (id, idclist) ->
       (* TODO: XY *)
       failwith "Unhandled ir3exp: MdCall3"
    | ObjectCreate3 s ->
       (* TODO: XY *)
       failwith "Unhandled ir3exp: ObjectCreate3" in
  aux ir3exp

let ir3_stmts_to_arm ir3stmts =
  let rec aux ir3stmts =
    match ir3stmts with
    | [] -> []
    | stmt :: rest ->
       begin
         match stmt with
         | PrintStmt3 idc ->
            let armdata,armlitinstr,lbl = idc3_to_arm_literal idc in
            let ldinstr = LDR ("", "", "a1", LabelAddr ("="^lbl)) in
            let blinstr = BL ("", "printf(PLT)") in
            (armdata, armlitinstr @ [ldinstr;blinstr]) :: aux rest
         | Label3 lbl ->
            (* TODO: Vincent *)
            let linstr = Label (string_of_int lbl) in
		    ([], [linstr]) :: aux rest   
         | IfStmt3 (condexp, lbl) ->
            (* TODO: Vincent *)            
		    (* If false goto else; 
		    cmp v5,#0
		    moveq v5,#0
		    movne v5,#1
		    cmp v5,#0
		    beq .1
		    *)
		    let (condinstr, reg) = ir3_exp_to_arm condexp in
		    (*let cmpinstr = CMP ("", reg, ImmedOp "#0") in
		    let moveqinstr = MOV ("eq", false, reg, ImmedOp "#0") in
		    let movneinstr = MOV ("ne", false, reg, ImmedOp "#1") in*)
		    let cmpinstr = CMP ("", reg, ImmedOp "#0") in
		    let beqinstr = B ("eq", (string_of_int lbl)) in
		    ([], condinstr @ [cmpinstr; beqinstr]) :: aux rest
         | Goto3 lbl ->
            (* TODO: Vincent *)
		    let binstr = B ("", (string_of_int lbl)) in
		    ([], [binstr]) :: aux rest
         | ReadStmt3 id3 ->
            (* Not compiling to arm *)
            failwith "Unhandled ir3stmt: ReadStmt3"
         | AssignStmt3 (id3, exp) ->
            let armdata,arminstr,reg = ir3_exp_to_arm exp in
            let id3reg = (idc3_to_arm_literal id3) in
            let stinstr = STR ("", "", id3reg, reg) in
            (arndata, arminstr @ [stinstr]) :: aux rest
         | AssignDeclStmt3 (typ, id3, exp) ->
            (* TODO: Vincent *)
		    (* This is not used in jlite_toir3.ml *)
            failwith "Unhandled ir3stmt: AssignDeclStmt3"
         | AssignFieldStmt3 (lhsexp, rhsexp) ->
            (* TODO: Vincent *)
		    let (lhsexpinstr, reglhs) = ir3_exp_to_arm lhsexp in
		    let (rhsexpinstr, regrhs) = ir3_exp_to_arm rhsexp in
		    let moveqinstr = MOV ("", false, reglhs, regrhs) in
		    ([], lhsexpinstr @ rhsexpinstr @ [moveqinstr]) :: aux rest           
         | MdCallStmt3 exp ->
            (* TODO: JS *)
            failwith "Unhandled ir3stmt: MdCallStmt3"
         | ReturnStmt3 id3 ->
            (* TODO: JS *)
            failwith "Unhandled ir3stmt: ReturnStmt3"
         | ReturnVoidStmt3 ->
            (* TODO: JS *)
            failwith "Unhandled ir3stmt: ReturnVoidStmt3"
       end in
  aux ir3stmts

(* TODO: Soares *)
let ir3_class_to_arm cls = failwith "Not implemented"

let ir3_md_to_arm md =
  let armdata, arminstr = List.split (ir3_stmts_to_arm md.ir3stmts) in
  let armdata, arminstr = List.concat armdata, List.concat arminstr in
  (armdata, [ Label md.id3 ] @ arminstr)

let ir3_to_arm (classes, mainmd, mdlist) =
  (* let _armmdlist = (List.concat (List.map ir3_md_to_arm mdlist)) in *)
  let armmaindata, armmainmdinstr = ir3_md_to_arm mainmd in
  (* arm directives *)
  let datadir = PseudoInstr ".data" in
  let textdir = PseudoInstr ".text" in
  (* boilerplate to 'declare' main*)
  let declmain = [PseudoInstr ".global main"; PseudoInstr ".type main, %function"] in
  [datadir] @ armmaindata @ [textdir] @ declmain @ armmainmdinstr
