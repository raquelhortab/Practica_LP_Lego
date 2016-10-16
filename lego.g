#header
<<
#include <string>
#include <iostream>
#include <map>
using namespace std;



// struct to store information about tokens
typedef struct {
  string kind;
  string text;
} Attrib;

// function to fill token information (predeclaration)
void zzcr_attr(Attrib *attr, int type, char *text);

// fields for AST nodes
#define AST_FIELDS string kind; string text;
#include "ast.h"

// macro to create a new AST node (and function predeclaration)
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST* createASTnode(Attrib* attr,int ttype, char *textt);
>>

<<
#include <cstdlib>
#include <cmath>

//global structures
AST *root;



// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {
/*  if (type == ID) {
    attr->kind = "id";
    attr->text = text;
  }
  else {*/
    attr->kind = text;
    attr->text = "";
//  }
}

// function to create a new AST node
AST* createASTnode(Attrib* attr, int type, char* text) {
  AST* as = new AST;
  as->kind = attr->kind; 
  as->text = attr->text;
  as->right = NULL; 
  as->down = NULL;
  return as;
}


/// create a new "list" AST node with one element
AST* createASTlist(AST *child) {
 AST *as=new AST;
 as->kind="list";
 as->right=NULL;
 as->down=child;
 return as;
}

/// get nth child of a tree. Count starts at 0.
/// if no such child, returns NULL
AST* child(AST *a,int n) {
AST *c=a->down;
for (int i=0; c!=NULL && i<n; i++) c=c->right;
return c;
}



/// print AST, recursively, with indentation
void ASTPrintIndent(AST *a,string s)
{
  if (a==NULL) return;

  cout<<a->kind;
  if (a->text!="") cout<<"("<<a->text<<")";
  cout<<endl;

  AST *i = a->down;
  while (i!=NULL && i->right!=NULL) {
    cout<<s+"  \\__";
    ASTPrintIndent(i,s+"  |"+string(i->kind.size()+i->text.size(),' '));
    i=i->right;
  }
  
  if (i!=NULL) {
      cout<<s+"  \\__";
      ASTPrintIndent(i,s+"   "+string(i->kind.size()+i->text.size(),' '));
      i=i->right;
  }
}

/// print AST 
void ASTPrint(AST *a)
{
  while (a!=NULL) {
    cout<<" ";
    ASTPrintIndent(a,"");
    a=a->right;
  }
}




/*////////////////////////////////////
 * INTERPRETACIÓ DE L'ARBRE
 */

typedef struct{
    int x, y;
    int h,w;
} bloc;

typedef struct{
    int n,m;
    vector<vector<int> > altura;
    map<string, bloc> blocs;
} Graella;

Graella g;

map<string,AST*> funcions; //mapa de les funcions DEF 

void inicialitzarGraella(int n, int m){
    g.n = n;
    g.m = m;
    g.altura = vector<vector<int> > (n, vector<int> (g.m));
}

void processarDefinicions(AST *defs){
    //recorrer tots els fills i guardar al map de funcions
    AST *fill = child(defs,0);
    for(int i = 0; fill!=NULL; ++i){
        funcions.insert(fill);
        //següent fill
        fill = child(defs,i);
    }
    return;
}

void executarOperacions(AST *ops){
    
}

void executeListInstrucctions(AST *a){
    
    //graella
    AST *graella = child(a,0);
    //operacions
    AST *ops = child(a,1);
    //definicions
    AST *defs = child(a,2);
    
    //inicialitzar graella
    int n = atoi(child(graella,0)->text);
    int m = atoi(child(graella,1)->text);
    inicialitzarGraella(n,m);
    
    processarDefinicions(defs);
    
    executarOperacions(ops);
    
    
    //print?
    
}











////////////////////////////////////////////////////////////







int main() {
  root = NULL;
  ANTLR(lego(&root), stdin);
  ASTPrint(root);
}
>>

//GRAMÀTICA
#lexclass START

#token NUM "[0-9]+"

#token GRID "Grid"

#token MOVE "MOVE"
#token PUSH "PUSH"
#token PLACE "PLACE"
#token AT "AT"

#token NORTH "NORTH"
#token SOUTH "SOUTH"
#token EAST "EAST"
#token WEST "WEST"

#token WHILE "WHILE"
#token FITS "FITS"
#token HEIGHT "HEIGHT"
#token AND "AND"
#token LESS "\<"
#token MORE "\>"
#token EQ "\="

#token DOT "\,"
#token LP "\("
#token RP "\)"
#token LC "\["
#token RC "\]"


#token DEF "DEF"
#token ENDEF "ENDEF"

#token ID "[a-zA-Z][a-zA-Z0-9]+"

#token SPACE "[\ \n]" << zzskip();>>


grid: GRID^ NUM NUM;

pos: LP! NUM DOT! NUM RP! <<#0=createASTlist(_sibling);>>;
dir: NORTH|SOUTH|EAST|WEST;
place: (PLACE^ pos AT pos);
ids: ID ( EQ^  ( place | bloc) |  ) ;
move: MOVE^ ID dir NUM;

bloc: (ID|pos) ((PUSH^|POP^) bloc| );

ops: (ids|move|height|bucle)* <<#0=createASTlist(_sibling);>>;

height: HEIGHT LP! ID RP!;
fits: FITS^ LP! ID DOT! NUM DOT! NUM DOT! NUM RP!;
cond: fits|height;
bucle: WHILE^ LP! cond RP! LC! ops RC!;

def: DEF^ ID ops ENDEF;
defs: (def)*;

lego: grid ops defs <<#0=createASTlist(_sibling);>>;
//....