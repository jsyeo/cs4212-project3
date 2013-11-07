open Arm_structs

open Ir3_structs

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

let idc3_to_arm_literal idc =
  match idc with
  | StringLiteral3 s ->
     ([Label (fresh_label()); PseudoInstr (sprintf ".asciz \"%s\"" s)],[])
  | IntLiteral3 i ->
     (* TODO: JS *)
     failwith "Unhandled idc3: IntLiteral3"
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
       failwith "Unhandled ir3exp: BinaryExp3"
    | UnaryExp3 (op, idc) ->
       (* TODO: XY *)
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
            let armdata,armlitinstr = idc3_to_arm_literal idc in
            let ldinstr = LDR ("", "", "a1", LabelAddr "=L1") in
            let blinstr = BL ("", "printf(PLT)") in
            (armdata, armlitinstr @ [ldinstr;blinstr]) :: aux rest
         | Label3 lbl ->
            (* TODO: Vincent *)
            failwith "Unhandled ir3stmt: Label3"
         | IfStmt3 (condexp, lbl) ->
            (* TODO: Vincent *)
            failwith "Unhandled ir3stmt: IfStmt3"
         | Goto3 lbl ->
            (* TODO: Vincent *)
            failwith "Unhandled ir3stmt: Goto3"
         | ReadStmt3 id3 ->
            (* Not compiling to arm *)
            failwith "Unhandled ir3stmt: ReadStmt3"
         | AssignStmt3 (id3, exp) ->
            (* TODO: Vincent *)
            failwith "Unhandled ir3stmt: AssignStmt3"
         | AssignDeclStmt3 (typ, id3, exp) ->
            (* TODO: Vincent *)
            failwith "Unhandled ir3stmt: AssignDeclStmt3"
         | AssignFieldStmt3 (lhsexp, rhsexp) ->
            (* TODO: Vincent *)
            failwith "Unhandled ir3stmt: AssignFieldStmt3"
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
  let data_dir = PseudoInstr ".data" in
  [data_dir] @ armmaindata @ armmainmdinstr
