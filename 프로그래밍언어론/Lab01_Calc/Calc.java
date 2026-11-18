import java.io.*;

class Calc {
    int token; int value; int ch;
    private PushbackInputStream input;
    final int NUMBER=256;

    Calc(PushbackInputStream is) {
        input = is;
    }

    int getToken( )  { /* tokens are characters */
        while(true) {
            try  {
	            ch = input.read();
                if (ch == ' ' || ch == '\t' || ch == '\r') ;
                else {
                    if (Character.isDigit(ch)) {
                        value = number( );
                        input.unread(ch);
                        return NUMBER;
                    }
                    else return ch;
	            }

	  } catch (IOException e) {
                System.err.println(e);
            }
        }
    }

    private int number( )  {
    /* number -> digit { digit } */
        int result = ch - '0';
        try  {
            ch = input.read();
            while (Character.isDigit(ch)) {
                result = 10 * result + ch -'0';
                ch = input.read(); 
            }
        } catch (IOException e) {
            System.err.println(e);
        }
        return result;
    }

    void error( ) {
        System.out.printf("parse error : %d\n", ch);
        System.exit(1); // 문법 오류 시 즉시 종료
    }

    void match(int c) { 
        if (token == c) 
	    token = getToken();
        else error();
    }

    void command( ) {
    /* command -> expr '\n' */
        Object result = expr();  // boolean과 정수 결과를 모두 처리하기 위해
        if (token == '\n') { /* end the parse and print the result */
            System.out.println(result);
        }
        else error();
    }
    
    Object expr() {
    /* <expr> -> <bexp> {& <bexp> | '|'<bexp>} | !<expr> | true | false */
    	Object result;
    	if (token == '!'){
    		// !<expr>
    		match('!');
    		result = !(boolean) expr();
    	}
    	else if (token == 't'){
    		// true
            // token은 한 글자씩 처리하기에 't'만 match하면 'rue'가 남아 command()의 token =='\n' 검사가 실패해 error()발생
            // 'true' 모두 match 처리
            match('t'); match('r'); match('u'); match('e');
    		result = true;
    	}
    	else if (token == 'f'){
    		// false
    		// <expr> -> false 가 나온 경우, token에 "false"를 char단위로 차례로 일치여부 확인 후, result에 false대입한다.
            match('f'); match('a'); match('l'); match('s'); match('e');
            result=false;
    	}
    	else {
    		/* <bexp> {& <bexp> | '|'<bexp>} */
    		result = bexp();
    		while (token == '&' || token == '|') {
    			if (token == '&'){
    				// '&'과 현재 token의 일치성 확인 후 논리연산 &을 위해 앞에 처리한 result와 다음 논리식을 rgt에 저장해 result에 &으로 boolean을 처리함
                    match('&');
                    boolean rgt=(boolean)bexp();
                    result=(boolean)result&rgt;
    			}
    			else if (token == '|'){
    				// '|'과 token의 일치성 확인 후, 논리식의 앞부분은 result, 뒷부분은 rgt에 저장해, result에 boolean으로 |으로 연산한 값을 대입
                    match('|');
                    boolean rgt=(boolean)bexp();
                    result=(boolean)result|rgt;
    			}
    		}
    	}
    	return result;
	}

    Object bexp( ) {
    /* <bexp> -> <aexp> [<relop> <aexp>] */
    	Object result;
    	int aexp1 = aexp();
    	if (token == '<' || token == '>' || token == '=' || token == '!'){// <relop>
            /* Check each string using relop(): "<", "<=", ">", ">=", "==", "!=" */
            // relop에 해당하는 char이 token에 저장되어 있다면 [...]에 해당하는 부분을 실행
            // 실행하는 경우, relop()를 불러 실제 연산자를 반환해, .equals("...")를 통해 string의 값 자체를 비교해 연산자 처리
            // 피 연산자는 좌변은 aexp1, relop()으로 연산자 문자열 받은 뒤, 우변은 aexp2로 파싱해 op에 맞는 비교수행
            String op = relop();
            int aexp2 = aexp();
            if(op.equals("<"))  result = aexp1 <  aexp2;
            else if (op.equals("<=")) result = aexp1 <= aexp2;
            else if (op.equals(">"))  result = aexp1 >  aexp2;
            else if (op.equals(">=")) result = aexp1 >= aexp2;
            else if (op.equals("==")) result = aexp1 == aexp2;
            else if (op.equals("!=")) result = aexp1 != aexp2;
            else { error(); result = false; }
        }
        else {
            result = aexp1;
        }
        return result;
	}

    String relop() {    	
    /* <relop> -> ( < | <= | > | >= | == | != ) */    	
    	String result = "";
    	// 현재 token은 한 글자의 문자 코드이기에 앞부분을 확인하고 연산자 문자열을 조립한 뒤 result에 string으로 대입 후 반환
        if (token == '<') {
            match('<');
            if (token == '=') { match('='); result = "<="; }
            else result = "<";
        }
        else if (token == '>') {
            match('>');
            if (token == '=') { match('='); result = ">="; }
            else result = ">";
        }
        else if (token == '=') {
            match('='); match('=');
            result = "==";
        }
        else if (token == '!') {
            match('!'); match('=');
            result = "!=";
        }
        return result;
	}

    int aexp() {
    /* aexp() : <aexp> -> <term> { + <term> | - <term> } */
        // <term> { + <term> } 뿐만 아니라  <term> { - <term> }또한 token으로 '-'여부 확인해 term을 연산자 실행
        int result = term();
        while (token == '+' || token == '-') {
            if (token == '+') {
                match('+');
                result += term();
            } else {
                match('-');
                result -= term();
            }
        }
        return result;
    }

    int term( ) {
    /* term() : <term> -> <factor> { * <factor> | / <factor> } */
        //<factor> { * <factor> } 뿐 아니라 나눗셈과정도 token을 확인해 진행
        int result = factor();
        while (token == '*' || token == '/') {
            if (token == '*') {
                match('*');
                result *= factor();
            } else {
                match('/');
                result /= factor();
            }
        }
        return result;
    }

    int factor() {
    /* factor(): <factor> -> [-] ( number | '(' <aexp> ')' ) */
    // <factor>에 대한 식이 negative할 수 있기에 '-'의 경우도 token을 확인해 별도로 저장해두고 해당 함수 반환시, '-'가 존재하면 result에 음수를 붙임
        int result = 0;
        boolean negative = false;
        if (token == '-') {          // optional unary minus
            match('-');
            negative = true;
        }
        if (token == '(') {
            match('(');
            result = aexp();
            match(')');
        }
        else if (token == NUMBER) {
            result = value;
            match(NUMBER);
        }
        else error();
        return negative ? -result : result;
    }

    void parse( ) {
        token = getToken(); // get the first token
        command();          // call the parsing command
    }

    public static void main(String args[]) { 
        Calc calc = new Calc(new PushbackInputStream(System.in));
        while(true) {
            System.out.print(">> ");
            calc.parse();
        }
    }
}