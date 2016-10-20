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
    string id;
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

void push(bloc a, bloc b){
    int cont = 0;
    int alt = 1;

    bool stop = false;
    bool trobat = false;
    
    //recorrer tot el bloc b, on serà col·locat el bloc a
    for(int j = b.y; j <= (b.y + b.h) and not trobat; ++j){
        for(int i = b.x; i <= (b.x + b.w) and not trobat; ++i){
            ++cont;
            //si s'ha trobat espai horitzontal
            if(cont == a.w and g.altura[i][j] == alt){
                //mirar si hi cap el bloc senser
                for(int k = i-(a.w -1); k <= i and not stop; ++k){
                    for(int l = j; l < j+a.h and not stop; ++l){
                        if(altura != alt) stop = true;
                    }
                }
                //hi cap:
                trobat == true;
                //////////////////////////////que fer?????
                
            }
            if(g.altura[i][j] != alt){
                cont = 0;
                alt = g.altura[i][j];
            }
            if(i == (b.x + b.w)) cont == 0;
        }
    }
    
    cout<<"ERROR no es pot fer aquest PUSH"<<endl;
}

void pop(bloc a, bloc b){
    //arreglem l'altura
    for(int i = a.x; i <= (a.x + a.w); ++i){
        for(int j = a.y; j <=(a.y + a.h); ++j){
            --g.altura[i][j];
        }
    }
    //eliminem el bloc
    g.blocs.erase(a.id);
}

bloc processarBloc(AST *a, string id){
    bloc b;
    if(a->kind ==  PLACE){
        AST mida = child(a,0);
        AST pos = child(b,1);
        b.id = id;
        b.w = child(mida,0);
        b.h = child(mida,1);
        b.x = child(pos,0);
        b.y = child(pos,1);
        return b;
    }
    else if(a->kind == "PUSH"){
        //fer recursiu, pensar
    }
    else if(a->kind == "POP"{
        //fer recursiu, pensar
    }
    
    else cout<<"ERROR: no és un bloc a processar"<<endl;
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
    AST temp = child(ops,0);
    while(temp != NULL){
        
        if(temp->kind == "="){
            string id = child(temp,0)->text;
            bloc b = processarBloc(child(temp,1), id);
            g.blocs.insert(pair<id,b>);
        }
        else if (temp->kind == "MOVE"){
            string id = child(temp,0)->text; //id del bloc a moure
            string dir = child(temp,1)->kind; //direcció cap on moure'l
            int mov = atoi(child(temp,2)->text); //quant s'ha de 
            
            if(dir == "NORTH"){
                --(g.blocs.find(id)->second).y;
            }
            else if(dir == "SOUTH"){
                ++(g.blocs.find(id)->second).y;
            }
            else if(dir == "EAST"){
                ++(g.blocs.find(id)->second).x;
            }
            else if(dir == "WEST"){
                --(g.blocs.find(id)->second).x;
            }
            else cout<<"ERROR: això no és una direcció"<<endl;
        }
        else if(temp->kind == "ID"){
            //executar funcio
            executarOperacions(funcions.find(temp->text)->second;
        }            
        else if(temp->kind == "WHILE"){
            
        }
        else if(temp->kind == "HEIGHT"){
            string id = child(temp,0);
            
        }
            
            
        }
        
        //següent operacio
        temp = temp->right;
    }
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