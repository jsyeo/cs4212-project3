class Main {
    void main() {
        Foo f;
        f = new Foo();
        f.b = 78;
        println(f.b);
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
