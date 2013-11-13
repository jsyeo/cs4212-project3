
(* ===================================================== *)
(* ============== CS41212 Compiler Design ============== *)
(* ===================================================== *)

open Printf

open Jlite_annotatedtyping

open Ir3_structs
open Jlite_toir3

let (@@) f x = f x

let source_files = ref []

let usage_msg = Sys.argv.(0) ^ " <source files>"

let set_source_file arg = source_files := arg :: !source_files

let print_all = ref false

let parse_file file_name =
  let org_in_chnl = open_in file_name in
  let lexbuf = Lexing.from_channel org_in_chnl in
  try
    let prog =  Jlite_parser.input (Jlite_lexer.token file_name) lexbuf in
    close_in org_in_chnl;
    prog
  with
    End_of_file -> exit 0

let process file_name prog  =
  begin
    let typedprog = Jlite_annotatedtyping.type_check_jlite_program prog in
    let ir3prog = Jlite_toir3.jlite_program_to_IR3 typedprog in
    let armprog = Arm_generator.ir3_to_arm ir3prog in
    let _ =
      if !print_all then
        let _ = print_string @@ Jlite_structs.string_of_jlite_program prog in
        let _ = print_string @@ Jlite_structs.string_of_jlite_program typedprog in
        let _ = print_string @@ Ir3_structs.string_of_ir3_program ir3prog in
        let _ = print_string @@ Arm_structs.string_of_arm_prog armprog in
        ()
      else
        let _ = print_string @@ Arm_structs.string_of_arm_prog armprog in
        () in
    ()
  end

let _ =
  begin
    Arg.parse [
      ("-a", Arg.Unit (fun () -> print_all := true), "Prints the typed program, ir3 immediate form and the arm assembly.")
    ] set_source_file usage_msg ;
    match !source_files with
    | [] -> print_string "No file provided \n"
    | x::_->
       let prog = parse_file x in
       process x prog
  end
