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
     if i < 256 then
       let r = fresh_reg_var() in
       let movinstr = MOV ("", false, r, ImmedOp ("#" ^ string_of_int i)) in
       ([],[movinstr],r)
     else
       (* TODO: Handle big numbers >_< *)
       failwith "Unhandled idc3: IntLiteral3"
  | BoolLiteral3 b ->
     let armboolrep =
       if b then
         1
       else
         0 in
     let r = fresh_reg_var() in
     let movinstr = MOV ("", false, r, ImmedOp ("#" ^ string_of_int armboolrep)) in
     ([],[movinstr],r)
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
       let cmpinstr = CMP ("", reg1, RegOp reg2) in
       let movltinstr = MOV ("lt", false, frv, ImmedOp "#1") in
       let movgeinstr = MOV ("ge", false, frv, ImmedOp "#0") in
       [cmpinstr; movltinstr; movgeinstr]
    | RelationalOp "<=" ->
       let cmpinstr = CMP ("", reg1, RegOp reg2) in
       let movltinstr = MOV ("le", false, frv, ImmedOp "#1") in
       let movgeinstr = MOV ("gt", false, frv, ImmedOp "#0") in
       [cmpinstr; movltinstr; movgeinstr]
    |  RelationalOp ">" ->
       let cmpinstr = CMP ("", reg1, RegOp reg2) in
       let movltinstr = MOV ("gt", false, frv, ImmedOp "#1") in
       let movgeinstr = MOV ("le", false, frv, ImmedOp "#0") in
       [cmpinstr; movltinstr; movgeinstr]
    | RelationalOp ">=" ->
       let cmpinstr = CMP ("", reg1, RegOp reg2) in
       let movltinstr = MOV ("ge", false, frv, ImmedOp "#1") in
       let movgeinstr = MOV ("lt", false, frv, ImmedOp "#0") in
       [cmpinstr; movltinstr; movgeinstr]
    | RelationalOp "==" ->
       let cmpinstr = CMP ("", reg1, RegOp reg2) in
       let movltinstr = MOV ("eq", false, frv, ImmedOp "#1") in
       let movgeinstr = MOV ("ne", false, frv, ImmedOp "#0") in
       [cmpinstr; movltinstr; movgeinstr]
    | RelationalOp "!=" ->
       let cmpinstr = CMP ("", reg1, RegOp reg2) in
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
          let armdata, arminstr, reg = idc3_to_arm_literal idc in
          let frv = fresh_reg_var() in
          let armexprinstr = match op with
          | UnaryOp "-" ->
             [RSB ("", false, frv, reg, ImmedOp "#0")]
          | UnaryOp "!" ->
             [RSB ("", false, frv, reg, ImmedOp "#1")]
          | _ -> failwith "Typecheck fails in front, else won't reach here"
          in
          (armdata, arminstr @ armexprinstr, frv)
        end
    | FieldAccess3 (id1, id2) ->
       (* TODO: XY *)
       failwith "Unhandled ir3exp: FieldAccess3"
    | Idc3Expr idc ->
       (* TODO: XY *)
       let armdata, arminstr, reg = idc3_to_arm_literal idc in
       (armdata, arminstr, reg)
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
            begin
              match idc with
              | IntLiteral3 _
              | BoolLiteral3 _ ->
                 let armdata,armlitinstr,reg = idc3_to_arm_literal idc in
                 let lbl = fresh_label() in
                 let formatdata = [Label lbl; PseudoInstr (".asciz \"%d\"")] in
                 let ldinstr = LDR ("", "", "a1", LabelAddr ("="^lbl)) in
                 let movinstr = MOV ("", false, "a2", RegOp reg) in
                 let blinstr = BL ("", "printf(PLT)") in
                 (armdata @ formatdata, armlitinstr @ [ldinstr; movinstr; blinstr]) :: aux rest
              | _ ->
                 let armdata,armlitinstr,lbl = idc3_to_arm_literal idc in
                 let ldinstr = LDR ("", "", "a1", LabelAddr ("="^lbl)) in
                 let blinstr = BL ("", "printf(PLT)") in
                 (armdata, armlitinstr @ [ldinstr;blinstr]) :: aux rest
            end
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
            let (conddata, condinstr, reg) = ir3_exp_to_arm condexp in
            (*let cmpinstr = CMP ("", reg, ImmedOp "#0") in
            let moveqinstr = MOV ("eq", false, reg, ImmedOp "#0") in
            let movneinstr = MOV ("ne", false, reg, ImmedOp "#1") in*)
            let cmpinstr = CMP ("", reg, ImmedOp "#0") in
            let beqinstr = B ("eq", (string_of_int lbl)) in
            (conddata, condinstr @ [cmpinstr; beqinstr]) :: aux rest
         | Goto3 lbl ->
            (* TODO: Vincent *)
            let binstr = B ("", (string_of_int lbl)) in
            ([], [binstr]) :: aux rest
         | ReadStmt3 id3 ->
            (* Not compiling to arm *)
            failwith "Unhandled ir3stmt: ReadStmt3"
         | AssignStmt3 (id3, exp) ->
            let armdata,arminstr,reg = ir3_exp_to_arm exp in
            let id3data, id3instr, id3reg = (idc3_to_arm_literal (Var3 id3)) in (* TODO - Check whether this id3 wrapping is correct *)
            let stinstr = STR ("", "", id3reg, Reg reg) in
            (armdata @ id3data, arminstr @ id3instr @ [stinstr]) :: aux rest
         | AssignDeclStmt3 (typ, id3, exp) ->
            (* TODO: Vincent *)
            (* This is not used in jlite_toir3.ml *)
            failwith "Unhandled ir3stmt: AssignDeclStmt3"
         | AssignFieldStmt3 (lhsexp, rhsexp) ->
            (* TODO: Vincent *)
            let (lhsexpdata, lhsexpinstr, reglhs) = ir3_exp_to_arm lhsexp in
            let (rhsexpdata, rhsexpinstr, regrhs) = ir3_exp_to_arm rhsexp in
            let moveqinstr = MOV ("", false, reglhs, RegOp regrhs) in
            (lhsexpdata @ rhsexpdata, lhsexpinstr @ rhsexpinstr @ [moveqinstr]) :: aux rest           
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
  let stminstr = STMFD ["fp";"lr"] in
  let ldminstr = LDMFD ["fp";"pc"] in
  let armdata, arminstr = List.split (ir3_stmts_to_arm md.ir3stmts) in
  let armdata, arminstr = List.concat armdata, List.concat arminstr in
  (armdata, [ Label md.id3; stminstr ] @ arminstr @ [ldminstr])

let ir3_to_arm (classes, mainmd, mdlist) =
  (* let _armmdlist = (List.concat (List.map ir3_md_to_arm mdlist)) in *)
  let armmaindata, armmainmdinstr = ir3_md_to_arm mainmd in
  (* arm directives *)
  let datadir = PseudoInstr ".data" in
  let textdir = PseudoInstr ".text" in
  (* boilerplate to 'declare' main*)
  let declmain = [PseudoInstr ".global main"; PseudoInstr ".type main, %function"] in
  [datadir] @ armmaindata @ [textdir] @ declmain @ armmainmdinstr
