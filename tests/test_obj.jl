class Main {
    void main() {
        Foo f;
        Int i;
        i = 1;
        f = new Foo();
        i = f.b;
        println(i);
    }
}

class Foo {
    Int a;
    Int b;
    Int c;
    Int add(Int x, Int y) {
        return x + y;
    }
}
