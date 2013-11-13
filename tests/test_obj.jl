class Main {
    void main() {
        Foo f;
        Int result;
        Int a;
        Int b;
        Int c;
        Int d;
        Int e;
        f = new Foo();
        f.b = 78;
        a = 1;
        b = 2;
        c = 3;
        d = 4;
        e = 5;
        println(f.b);
        println(a + b + c + d + e);
        println(" SEPARATOR ");
        result = f.add(3,5);
        println(result);
        println(a + b + c + d + e);
        println(f.b);
        f.set_b(123);
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
    void set_b(Int x) {
        b = x;
        return;
    }
   

}
