jlite_main.native:
	ocamlbuild jlite_main.native

clean:
	rm -rf _build
	rm -rf *.native

.PHONY: clean jlite_main.native
