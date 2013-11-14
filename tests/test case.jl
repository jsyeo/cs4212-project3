class Main { 
	void main() {
	
		println("### Start of testing ###");
		println("Assumption is made that println works.");
		println("");
		println("testing AritmeticOp");
		Int a; 
		Int b;
		Int c;
		Int d;
		Int e;
		Int f;
		a = 1;
		b = 2;
		c = 3;
		d = 4;
		e = 5;
		f = a+b+c+d+e;
		println(a*b);
		println(a+b);
		println(e);
		println(a+b+c+d+e);
		println(e-d);
		println((a+a)*(a+a)-d+e);
		println(-a);
		println(f);
		f = 0;
		println(f);
		f = a;
		println(f);
		println("Here we will test if f will be changed to 2.");
		a = 2;
		println(f);
		
		println("");
		println("Lets check boolean now.");
		Bool b1;
		Bool b2;
		Bool b3;
		b1 = true;
		b2 = false;
		b3 = false;
		println(b1);
		println(b2);
		println("testing RelationalOp");
		println(b1||b2);
		println(b2||b3);
		println(b1&&b2);
		println(b2&&b3);
		b3 = b1 || b2;
		println(e>a);
		println(f>=a);
		println(f<=a);
		println(f>e);
		println(f != e); // I am not sure what this result supposed to be actually
		println(f == a);
		
		println("testing UnaryExp3");
		println(!b1);
		println(!b2);
		println(b3);
		println(!b3);
		
		classA aobj;
		aobj = new classA();
		aobj.initB();
		aobj.aa = e;
		aobj.ab = true;
		aobj.as = "class A string";
		println("");
		println("testing of objects");
		println("testing AssignFieldStmt and FieldAccess");
		println(aobj.aa);
		println(aobj.ab);
		println(aobj.as);
		println(aobj.aa + 2);
		println(aobj.aob.bs);
		aobj.aob.bs = "I am testing alot things at the same time.";
		println(aobj.aob.bs);
			
		println("");
		println("Let test methods now");
		Int res;
		// 2 + 2 + 3 + 4
		res = aobj.sumFour(a,b,c,d);
		println(res);
		println(aobj.sumFour(a,b,c,d));
		println(aobj.sumFour(a,a,a,a+a+a+a+a);
		println("test 7 parameters");
		res = aobj.aob.sumMany(a,a,a,a,a,a,a);
		println(res);
		println("test 7 parameters with 7 local variables");
		res = aobj.sumManyUsingLocal(a,a,a,a,a,a,a);
		println(res);
		println(aobj.sumClassVar(a));
		println(aobj.sumClassVar2(a));
		
		println("");
		println("Using classB to test now");
		classB bobj;
		bobj = new classB();
		println("testing if statement");
		println(bobj.sumUpTo(3));
		println(bobj.sumUpTo(f));
		println(bobj.checkBool(true));
		println(bobj.checkBool(false));
		println(bobj.checkBool(aobj.ab));
		
		println("testing mulTyp");
		println(bobj.mulTyp(1, true, 3, "tt", "wrong", true));
		println(bobj.mulTyp(1, true, 4, "wrong", "tf", false));
		println(bobj.mulTyp(4, false, 3, "wrong", "ft", true));
		println(bobj.mulTyp(3, false, 3, "wrong", "ff", false));
		
		println("");
		println(bobj.sumUpTo(1+2+3+4+5-5-4-3-2-1));
		println(bobj.retI(2));
		println(bobj.retS("S"));
		println(bobj.retB(true));
		println(bobj.retI(aobj.aa+2+3-e));
		println(bobj.retB(true || false || aobj.ab));
		println(bobj.retB(false || false || aobj.ab));
		println(bobj.retB(false || false || !aobj.ab));
	}
	
	class classA {
		Int aa;
		Bool ab;
		String as;
		classB aob;
		
		void initB(){
			aob = new classB();
			aob.bs = "I don't know what else to test";
			return;
		}
		
		Int sumClassVar(Int a) {
			return a + aa;
		}
		
		Int sumClassVar2(Int a) {
			return a + this.aa;
		}
		
		Int sumFour(Int a, Int b, Int c, Int d) {
			return a+b+c+d;
		}
		
		Int sumManyUsingLocal((Int a, Int b, Int c, Int d, Int e, Int f, Int g) {
			Int ta;
			Int tb;
			Int tc;
			Int td;
			Int te;
			Int tf;
			Int tg;
			Int res;
			Int res2;
			Int res3;
			res = ta + tb;
			res2 = tc + td;
			res3 = te + tf + tg;
			res = res + res2 + res3;
			return res;
		}
	}
	
	class classB {
		String bs;
		
		Int sumMany(Int a, Int b, Int c, Int d, Int e, Int f, Int g) {
			Int tempRes;
			tempRes = a + b + c + d + e + f + g;
			return tempRes;
		}
		
		Int checkBool (Bool b) {
			if (b && true) {
				return 1;
			} else {
				return 0;
			}
		}
		
		Int sumUpTo(Int a){
			if (a == 0) {
				return a;
			} else {
				return a + sumUpTo(a-1);
			}
		}
		
		Int mulTyp(Int a, Bool b, Int c, String d, String e, Bool f) {
			while (a < c) {
				a = a + 1;		
			}
			if (b || f) {
				println(d);
				return a;
			} else {
				println(e);
				return c;
			}						
		}
		
		Bool retB (Bool b){
			return b;
		}
		
		Int retI (Int i) {
			return i;
		}
		
		String retS (String s) {
			return s;
		}
	}
	
	
}