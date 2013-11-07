open Arm_structs

open Ir3_structs

open Printf

let idc3_to_arm_literal idc3 =
  match idc3 with
  | StringLiteral3 s ->
     (* TODO: Increment label *)
     ([Label "L1"; PseudoInstr (sprintf ".asciz \"%s\"" s)],[])
  | _ -> failwith "idc3_to_arm_literal: not handled case"

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
         | _ -> ([],[]) :: aux rest
       end in
  aux ir3stmts

let ir3_md_to_arm md =
  let armdata, arminstr = List.split (ir3_stmts_to_arm md.ir3stmts) in
  let armdata, arminstr = List.concat armdata, List.concat arminstr in
  (armdata, [ Label md.id3 ] @ arminstr)

let ir3_to_arm (classes, mainmd, mdlist) =
  (* let _armmdlist = (List.concat (List.map ir3_md_to_arm mdlist)) in *)
  let armmaindata, armmainmdinstr = ir3_md_to_arm mainmd in
  let data_dir = PseudoInstr ".data" in
  [data_dir] @ armmaindata @ armmainmdinstr
