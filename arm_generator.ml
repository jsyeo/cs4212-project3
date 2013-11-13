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
let fresh_maker prefix max =
  let count = ref (-1) in
  (fun () ->
    count := ((!count + 1) mod max) + 1;
    prefix ^ string_of_int !count)

let fresh_label = fresh_maker "L" 1000

let fresh_arg_reg = fresh_maker "a" 4

let fresh_reg_var = fresh_maker "v" 5

let idc3_to_arm_literal offsettbl (idc:idc3)
    : (arm_instr list * arm_instr list * string) =
  match idc with
  | StringLiteral3 s ->
    let l = fresh_label() in
    let r = fresh_reg_var() in
    let ldinstr = LDR ("", "", r, LabelAddr ("="^l)) in
    ([Label l; PseudoInstr (sprintf ".asciz \"%s\"" s)],[ldinstr],r)
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
    let r = fresh_reg_var() in
    let (offset, _) = Hashtbl.find offsettbl id3 in
    let ldrinstr = LDR ("", "", r, RegPreIndexed ("fp", offset, false)) in
    ([],[ldrinstr],r)

let ir3_exp_to_arm clstbl offsettbl ir3exp =
  let rec aux ir3exp =
    match ir3exp with
    | BinaryExp3 (op, idc1, idc2) ->
       (* TODO: XY *)
      begin
        let (arm1data,arm1instr,reg1),(arm2data,arm2instr,reg2) = (idc3_to_arm_literal offsettbl idc1),(idc3_to_arm_literal offsettbl idc2) in
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
        let armdata, arminstr, reg = idc3_to_arm_literal offsettbl idc in
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
      let (offset, typ) = Hashtbl.find offsettbl id1 in
      begin
        match typ with
        | ObjectT typ ->
          let varstbl = Hashtbl.find clstbl typ in
          let id2offset = Hashtbl.find varstbl id2 in
          let r = fresh_reg_var() in
          let ldid1instr = LDR ("", "", r, RegPreIndexed ("fp", offset, false)) in
           (* TODO : Check whether using the same register is correct *)
          let ldid2instr = LDR ("", "", r, RegPreIndexed (r, id2offset, false)) in
          ([], [ldid1instr; ldid2instr], r)
        | _ ->
          failwith "Typecheck fails in front, else won't reach here"
      end
    | Idc3Expr idc ->
       (* TODO: XY *)
      let armdata, arminstr, reg = idc3_to_arm_literal offsettbl idc in
      (armdata, arminstr, reg)
    | MdCall3 (id, idclist) ->
       (* TODO: XY *)
      (* let paramscount = List.length idclist in *)
      (* let subspinstr = SUB ("", false, "sp", "sp", ImmedOp ("#" ^ (string_of_int (paramscount * 4)))) in *)
      (* let rec push_params_to_stack count idclist datalist instrlist = *)
      (*   match idclist with *)
      (*   | [] -> (datalist, instrlist) *)
      (*   | idc3 :: rest -> *)
      (*     let (idc3data, idc3instr, idc3res) = idc3_to_arm_literal offsettbl idc3 in *)          
      failwith "Unhandled ir3exp: MdCall3"
    | ObjectCreate3 cname ->
      (* TODO: XY *)
      let varstbl = Hashtbl.find clstbl cname in
      let varsnum = Hashtbl.length varstbl in
      let movinstr = MOV ("", false, "a1", (ImmedOp ("#" ^ (string_of_int (varsnum * 4))))) in
      let blinstr = BL ("", "_Znwj(PLT)") in
      let r = fresh_reg_var() in
      let movresinstr = MOV ("", false, r, RegOp "a1") in
      ([], [movinstr; blinstr; movresinstr], r) in
  aux ir3exp

let ir3_stmts_to_arm clstbl offsettbl ir3stmts =
  let rec aux ir3stmts =
    match ir3stmts with
    | [] -> []
    | stmt :: rest ->
      begin
        match stmt with
        | PrintStmt3 idc ->
          let gen_print_reg_instrs fmt idc =
            let armdata,armlitinstr,reg = idc3_to_arm_literal offsettbl idc in
            let lbl = fresh_label() in
            let formatdata = [Label lbl; PseudoInstr (".asciz "^ fmt)] in
            let ldinstr = LDR ("", "", "a1", LabelAddr ("="^lbl)) in
            let movinstr = MOV ("", false, "a2", RegOp reg) in
            let blinstr = BL ("", "printf(PLT)") in
            (armdata @ formatdata, armlitinstr @ [ldinstr; movinstr; blinstr]) in
          begin
            match idc with
            | IntLiteral3 _
            | BoolLiteral3 _ ->
              gen_print_reg_instrs "\"%d\"" idc :: aux rest
            | StringLiteral3 _ ->
              gen_print_reg_instrs "\"%s\"" idc :: aux rest
            | Var3 id ->
              let armdata,armlitinstr,reg = idc3_to_arm_literal offsettbl idc in
              let _, typ = Hashtbl.find offsettbl id in
              begin
                match typ with
                | IntT
                | BoolT ->	
                  let lbl = fresh_label() in
                  let formatdata = [Label lbl; PseudoInstr (".asciz \"%d\"")] in
                  let ldinstr = LDR ("", "", "a1", LabelAddr ("="^lbl)) in
                  let movinstr = MOV ("", false, "a2", RegOp reg) in
                  let blinstr = BL ("", "printf(PLT)") in
                  (armdata @ formatdata, armlitinstr @ [ldinstr; movinstr; blinstr]) :: aux rest
                | StringT ->
                  let movinstr = MOV ("", false, "a1", RegOp reg) in
                  let blinstr = BL ("", "printf(PLT)") in
                  (armdata, armlitinstr @ [movinstr;blinstr]) :: aux rest
                | _ -> failwith "Can't print Object types. WHUT? YOU MAD BRO?"
              end
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
          let (conddata, condinstr, reg) = ir3_exp_to_arm clstbl offsettbl condexp in
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
          (* TODO: retrieve offset from tbl and store exp *)
          let armdata,arminstr,res = ir3_exp_to_arm clstbl offsettbl exp in
          (* res can be either reg or lable >_< *)
          let (offset, typ) = Hashtbl.find offsettbl id3 in
          let stinstr = STR ("", "", res, RegPreIndexed ("fp", offset, false)) in
          (armdata, arminstr @ [stinstr]) :: aux rest
        | AssignDeclStmt3 (typ, id3, exp) ->
          (* TODO: Vincent *)
          (* This is not used in jlite_toir3.ml *)
          failwith "Unhandled ir3stmt: AssignDeclStmt3"
        | AssignFieldStmt3 (lhsexp, rhsexp) ->
          (* TODO: Vincent *)
          begin
            match lhsexp with
            | FieldAccess3 (id1, id2) ->
              let (offset, objtyp) = Hashtbl.find offsettbl id1 in
              let typ =
                match objtyp with
                | ObjectT t -> t
                | _ -> failwith "LOL" in
              let varstbl = Hashtbl.find clstbl typ in
              let id2offset = Hashtbl.find varstbl id2 in
              let (rhsexpdata, rhsexpinstr, regrhs) = ir3_exp_to_arm clstbl offsettbl rhsexp in
              let r = fresh_reg_var() in

              let ldid1instr = LDR ("", "", r, RegPreIndexed ("fp", offset, false)) in
              (* TODO : Check whether using the same register is correct *)              

              let strinstr = STR ("", "", regrhs, RegPreIndexed (r
, id2offset, false)) in
              (rhsexpdata, rhsexpinstr @ [ldid1instr; strinstr]) :: aux rest
            | _ -> failwith "IR3 generation failed in front, shouldn't reach this point"
          end
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


let ir3_md_to_arm clstbl md =
  let numlocals = List.length md.localvars3 in
  let stminstr = STMFD ["v1-v5";"fp";"lr"] in
  (* add fp, sp, #24 *)
  let initfp = ADD ("", false, "fp", "sp", ImmedOp "#24") in
  (* sub sp, sp, #(numlocals * 4) *)
  let allocstack = SUB ("", false, "sp", "sp", ImmedOp ("#" ^ string_of_int (numlocals * 4))) in
  let offsettbl = Hashtbl.create numlocals in
  let rec pop_tbl_locals count locals =
    match locals with
    | [] -> ()
    | (typ, id) :: rest ->
      let negoffset = - ((numlocals - count) * 4 + 24) in
      Hashtbl.add offsettbl id (negoffset, typ);
      pop_tbl_locals (count + 1) rest in
  let _ = pop_tbl_locals 0 md.localvars3 in
  let rec pop_tbl_params count params =
    match params with
    | [] -> ()
    | (typ, id) :: rest ->
      let offset = count * 4 in
      Hashtbl.add offsettbl id (offset, typ);
      pop_tbl_params (count + 1) rest in
  let _ = pop_tbl_params 1 md.params3 in
  let restoresp = SUB ("", false, "sp", "fp", ImmedOp ("#24")) in
  let ldminstr = LDMFD ["v1-v5";"fp";"pc"] in
  let armdata, arminstr = List.split (ir3_stmts_to_arm clstbl offsettbl md.ir3stmts) in
  let armdata, arminstr = List.concat armdata, List.concat arminstr in
  (armdata, [ Label md.id3; stminstr; initfp; allocstack ] @ arminstr @ [restoresp; ldminstr])

let ir3_to_arm (classes, mainmd, mdlist) =
  let clstbl = Hashtbl.create (List.length classes) in
  let _ = List.iter
    (fun (cname, vardecls) ->
      let varstbl = Hashtbl.create (List.length vardecls) in
      let count = ref 0 in
      let _ = List.iter
	(fun (_, id) ->
	  Hashtbl.add varstbl id (!count * 4);
	  count := !count + 1) vardecls in
      Hashtbl.add clstbl cname varstbl) classes in
  (* let _armmdlist = (List.concat (List.map ir3_md_to_arm mdlist)) in *)
  let armmaindata, armmainmdinstr = ir3_md_to_arm clstbl mainmd in
  (* arm directives *)
  let datadir = PseudoInstr ".data" in
  let textdir = PseudoInstr ".text" in
  (* boilerplate to 'declare' main*)
  let declmain = [PseudoInstr ".global main"; PseudoInstr ".type main, %function"] in
  [datadir] @ armmaindata @ [textdir] @ declmain @ armmainmdinstr
