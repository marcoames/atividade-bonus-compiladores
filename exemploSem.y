    
%{
  import java.io.*;
%}


%token IDENT, INT, DOUBLE, BOOL, NUM, STRING, FLOAT
%token LITERAL, AND, VOID, MAIN, IF
%token STRUCT

%right '='
%nonassoc '>'
%left '+'
%left AND
%left '[' 
%left '.'  

%type <sval> IDENT
%type <ival> NUM
%type <obj> type
%type <obj> exp
%type <obj> lvalue

%%
        
prog : { currClass = ClasseID.VarGlobal; currEscopo = null; } dList main ;

dList : decl dList 
      | declstruct dList
      | 
      ;

declstruct : STRUCT IDENT '{'   { TS_entry nodo = ts.pesquisa($2);
                                  if (nodo != null) {
                                      yyerror("(sem) struct <" + $2 + "> ja declarada");
                                  } else {
                                      nodo = new TS_entry($2, Tp_STRUCT, ClasseID.NomeStruct, currEscopo);
                                      ts.insert(nodo);
                                      currEscopo = $2;  
                                      currClass = ClasseID.CampoStruct;
                                  }
                                }
                                campoStruct 
                                '}' 
                                ';'
                                { 
                                      currEscopo = null;
                                      currClass = ClasseID.VarGlobal;
                                }
           ;

campoStruct : campoDecl campoStruct 
            | 
            ;

campoDecl : type IDENT ';'      { TS_entry structType = ts.pesquisa(currEscopo);
                                  if (structType != null) { // dentro de uma struct
                                    TS_entry fieldType = (TS_entry)$1;
                                    TS_entry nodo = new TS_entry($2, fieldType, ClasseID.CampoStruct, currEscopo);
                                    ts.insert(nodo);
                                  } else {
                                      yyerror("(sem) tipo da struct <" + currEscopo + "> não encontrado");
                                  } 
                                }
          ;



decl  : type IDENT ';'    {  TS_entry nodo = ts.pesquisa($2);
                            if (nodo != null) {
                              yyerror("(sem) variavel >" + $2 + "< jah declarada");
                            } else {
                              ts.insert(new TS_entry($2, (TS_entry)$1, currClass, currEscopo));
                            }
                          }                        
      ;

              //
              // faria mais sentido reconhecer todos os tipos como ident! 
              // 

type  : INT        {  $$ = Tp_INT;  }
      | DOUBLE     {  $$ = Tp_DOUBLE; }
      | BOOL       {  $$ = Tp_BOOL; }
      | FLOAT      {  $$ = Tp_FLOAT; }
      | STRING     {  $$ = Tp_STRING; }
      | IDENT      {  TS_entry nodo = ts.pesquisa($1);
                      if (nodo == null) {
                        yyerror("(sem) Nome de tipo <" + $1 + "> nao declarado ");
                        $$ = Tp_ERRO;
                      } else {
                        $$ = nodo;
                      }
                    }
      ;


main  :  VOID MAIN '(' ')' bloco ;

bloco : '{' listacmd '}';

listacmd  : listacmd cmd
          |
          ;

cmd :  exp ';' 
    |  IF '(' exp ')' cmd   { if (((TS_entry)$3) != Tp_BOOL) 
                                    yyerror("(sem) expressão (if) deve ser lógica "+((TS_entry)$3).getTipo());
                             }     
    ;


exp : exp '+' exp     { $$ = validaTipo('+', (TS_entry)$1, (TS_entry)$3); }
    | exp '>' exp     { $$ = validaTipo('>', (TS_entry)$1, (TS_entry)$3); }
    | exp AND exp     { $$ = validaTipo(AND, (TS_entry)$1, (TS_entry)$3); } 
    | NUM             { $$ = Tp_INT; }      
    | '(' exp ')'     { $$ = $2; }
    | lvalue          { $$ = $1; }                   
    | lvalue '=' exp  { $$ = validaTipo(ATRIB, (TS_entry)$1, (TS_entry)$3);  } 
    ;



  lvalue  : IDENT       { TS_entry nodo = ts.pesquisa($1);
                          if (nodo == null) {
                            yyerror("(sem) variável <" + $1 + "> não declarada"); 
                            $$ = Tp_ERRO;
                          } else
                            $$ = nodo.getTipo();
                        }
          | IDENT '[' exp ']'   { $$ = Tp_ERRO; }
          | lvalue '.' IDENT    { TS_entry nodo = (TS_entry) $1;
                                  if (nodo == null) {
                                    yyerror("(sem) struct <" + $1 + "> nao declarada");
                                    $$ = Tp_ERRO;
                                  } else if (nodo.getClasse() != ClasseID.NomeStruct) {
                                    yyerror("(sem) variável <" + nodo.getId() + "> nao e uma struct");
                                    $$ = Tp_ERRO;
                                  } else {
                                    TS_entry campo = ts.pesquisa($3);
                                    if (campo == null) {
                                      yyerror("(sem) campo <" + $3 + "> nao existe na struct " + $1);
                                      $$ = Tp_ERRO;
                                    } else {
                                      $$ = campo.getTipo();
                                    }
                                  }
                                }
        ;

%%

  private Yylex lexer;

  private TabSimb ts;

  public static TS_entry Tp_INT =  new TS_entry("int", null, ClasseID.TipoBase, "null");
  public static TS_entry Tp_DOUBLE = new TS_entry("double", null,  ClasseID.TipoBase, "null");
  public static TS_entry Tp_BOOL = new TS_entry("bool", null,  ClasseID.TipoBase, "null");
  public static TS_entry Tp_ERRO = new TS_entry("_erro_", null,  ClasseID.TipoBase, "null");
  public static TS_entry Tp_STRUCT = new TS_entry("struct", null,  ClasseID.TipoBase, "null");
  public static TS_entry Tp_FLOAT = new TS_entry("float", null,  ClasseID.TipoBase, "null");
  public static TS_entry Tp_STRING = new TS_entry("string", null,  ClasseID.TipoBase, "null");

  public static final int ARRAY = 1500;
  public static final int ATRIB = 1600;

  private String currEscopo;
  private ClasseID currClass;

  private int yylex () {
    int yyl_return = -1;
    try {
      yylval = new ParserVal(0);
      yyl_return = lexer.yylex();
    }
    catch (IOException e) {
      System.err.println("IO error :"+e);
    }
    return yyl_return;
  }


  public void yyerror (String error) {
    //System.err.println("Erro (linha: "+ lexer.getLine() + ")\tMensagem: "+error);
    System.err.printf("Erro (linha: %2d \tMensagem: %s)\n", lexer.getLine(), error);
  }


  public Parser(Reader r) {
    lexer = new Yylex(r, this);

    ts = new TabSimb();

    //
    // não me parece que necessitem estar na TS
    // já que criei todas como public static...
    //
    ts.insert(Tp_ERRO);
    ts.insert(Tp_INT);
    ts.insert(Tp_DOUBLE);
    ts.insert(Tp_BOOL);
    

  }  

  public void setDebug(boolean debug) {
    yydebug = debug;
  }

  public void listarTS() { ts.listar();}

  public static void main(String args[]) throws IOException {
    System.out.println("\n\nVerificador semantico simples\n");
    

    Parser yyparser;
    if ( args.length > 0 ) {
      // parse a file
      yyparser = new Parser(new FileReader(args[0]));
    }
    else {
      // interactive mode
      System.out.println("[Quit with CTRL-D]");
      System.out.print("Programa de entrada:\n");
        yyparser = new Parser(new InputStreamReader(System.in));
    }

    yyparser.yyparse();

      yyparser.listarTS();

      System.out.print("\n\nFeito!\n");
    
  }


   TS_entry validaTipo(int operador, TS_entry A, TS_entry B) {
       
         switch ( operador ) {
              case ATRIB:
                    if ( (A == Tp_INT && B == Tp_INT)                        ||
                         ((A == Tp_DOUBLE && (B == Tp_INT || B == Tp_DOUBLE))) ||
                         (A == B) )
                         return A;
                     else
                         yyerror("(sem) tipos incomp. para atribuicao: "+ A.getTipoStr() + " = "+B.getTipoStr());
                    break;

              case '+' :
                    if ( A == Tp_INT && B == Tp_INT)
                          return Tp_INT;
                    else if ( (A == Tp_DOUBLE && (B == Tp_INT || B == Tp_DOUBLE)) ||
                                            (B == Tp_DOUBLE && (A == Tp_INT || A == Tp_DOUBLE)) ) 
                         return Tp_DOUBLE;     
                    else
                        yyerror("(sem) tipos incomp. para soma: "+ A.getTipoStr() + " + "+B.getTipoStr());
                    break;

             case '>' :
                     if ((A == Tp_INT || A == Tp_DOUBLE) && (B == Tp_INT || B == Tp_DOUBLE))
                         return Tp_BOOL;
                      else
                        yyerror("(sem) tipos incomp. para op relacional: "+ A.getTipoStr() + " > "+B.getTipoStr());
                      break;

             case AND:
                     if (A == Tp_BOOL && B == Tp_BOOL)
                         return Tp_BOOL;
                      else
                        yyerror("(sem) tipos incomp. para op lógica: "+ A.getTipoStr() + " && "+B.getTipoStr());
                 break;
            }

            return Tp_ERRO;
           
     }
