#header
<<
#include <string>
#include <iostream>
#include <map>
#include <vector>
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

typedef struct{
    string id;
    int x, y;
    int h,w;
}t_bloc;

typedef struct{
    int n,m;
    vector<vector<int> > altura;
    map<string, t_bloc> blocs;
}Graella;


///declaració de funcions
t_bloc processarBloc(AST *a, string id);
bool fun_fits(t_bloc a, t_bloc b);
t_bloc push(AST *a1, AST *a2);
t_bloc pop(AST *a1, AST *a2);
void altura(int x, int y, int w, int h);
void id(int x, int y, int w, int h,string s_id,vector<vector<string> > vec_id);
void processarDefinicions(AST *defs);

void d(string s){
    cout<<s<<endl;
}

void d(int s){
    cout<<s<<endl;
}



// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {
  if (type == ID) {
    attr->kind = "ID";
    attr->text = text;
  }
  else if(type == NUM){
    attr->kind = "NUM";
    attr->text = text;
  }
  else {
    attr->kind = text;
    attr->text = text;}
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
void ASTPrint(AST *a){
  while (a!=NULL) {
    cout<<" ";
    ASTPrintIndent(a,"");
    a=a->right;
  }
}


/*////////////////////////////////////
 * INTERPRETACIÓ DE L'ARBRE
 */



Graella g;

map<string,AST*> funcions; //mapa de les funcions DEF 

void inicialitzarGraella(int n, int m){
    g.n = n;
    g.m = m;
    g.altura = vector<vector<int> > (n, vector<int>(m));
    
}

t_bloc processarBloc(AST *a, string id){
    t_bloc b;
    if(a->kind ==  "PLACE"){
        AST *mida = child(a,0);
        AST *pos = child(a,1);
        b.id = id;
        b.w = atoi((child(mida,0)->text).c_str());
        b.h = atoi((child(mida,1)->text).c_str());
        b.x = atoi((child(pos,0)->text).c_str());
        b.y = atoi((child(pos,1)->text).c_str());
        altura(b.x,b.y,b.w,b.h);
        cout << "OK: PLACE de "<<b.id<<endl;
        return b;
        
    }
    else if(a->kind == "list"){
        t_bloc b;
        b.w = atoi((child(a,0)->text).c_str());;
        b.h = atoi((child(a,1)->text).c_str());;
        b.x = b.y = 0;
        b.id = id;
        return b;
    }
    else if(a->kind == "PUSH"){
        AST *a = child(a,0);
        AST *b = child(a,1);
        t_bloc resultat = push(a,b);
        return resultat;
    }
    else if(a->kind == "POP"){
        AST *a = child(a,0);
        AST *b = child(a,1);
        t_bloc resultat = pop(a,b);
        return resultat;
    }
    
    cout<<"ERROR: no és un bloc a processar"<<endl;
    t_bloc null;
    null.id="NULL";
    return null;
}

bool fun_fits(t_bloc a, t_bloc b){
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
                        if(g.altura[k][l] != alt)stop = true;
                    }
                }
                return true;
            }
            if(g.altura[i][j] != alt){ //si l'altura és diferent
                cont = 0;
                alt = g.altura[i][j];
            }
            if(i == (b.x + b.w)) cont == 0; //si arriba a la vora dreta
        }
    }
    return false;
}

t_bloc push(AST *a1, AST *a2){
    
    //crear bloc, o buscar si ja existeix
    t_bloc a,b;
    if(a1->kind == "list") a = processarBloc(a1,"no_id");
    else a = (g.blocs.find(a1->text))->second;
                               
    if(a2->kind == "PUSH"){
        b = push(child(a2,0),child(a2,1));
    }
    else if (a2->kind == "POP"){
        b = pop(child(a2,0),child(a2,1));
    }
    else if(a2->kind == "ID"){
        b = g.blocs.find(a2->text)->second;
    }
    
    //si hi cap, col·locar-lo
    if(fun_fits(a,b)){
        g.blocs.insert(pair<string,t_bloc>(a.id,a));
        //modificar l'altura
        altura(a.x,a.y,a.w,a.h);
        cout << "OK: PUSH de "<<a.id<<" sobre "<<b.id<<endl;
        return b;
    }
    
    cout<<"ERROR no es pot fer aquest PUSH"<<endl;
    t_bloc null;
    null.id = "NULL";
    return null;
}

t_bloc pop(AST *a1, AST *a2){
    
    
    //crear bloc o buscar si ja existeix
    t_bloc a,b;
    
    if(a1->kind == "list") a = processarBloc(a1,"no_id");
    else a = (g.blocs.find(a1->text))->second;
                               
    if(a2->kind == "PUSH"){
        b = push(child(a2,0),child(a2,1));
    }
    else if (a2->kind == "POP"){
        b = pop(child(a2,0),child(a2,1));
    }
    else if(a2->kind == "ID"){
        b = g.blocs.find(a2->text)->second;
    }
    
    //arreglem l'altura
    for(int i = a.x; i <= (a.x + a.w); ++i){
        for(int j = a.y; j <=(a.y + a.h); ++j){
            --g.altura[i][j];
        }
    }
    //eliminem el bloc
    g.blocs.erase(a.id);
    cout << "OK: POP de "<<a.id<<" de "<<b.id<<endl;
    return b;
}

void altura(int x, int y, int w, int h){
    for(int i = x; i < x+w; ++i){
        for(int j = y; j < y+h; ++j){
            ++g.altura[i][j];
        }
    }
}

void f_id(int x, int y, int w, int h,string s_id,vector<vector<string> > &vec_id){

    for(int i = x; i < x+w; ++i){
        for(int j = y; j < y+h; ++j){
            vec_id[i][j] = s_id;
        }
    }
}


void processarDefinicions(AST *defs){

    //recorrer tots els fills i guardar al map de funcions

    if(child(defs,0) != NULL){
       
        AST *fill = child(defs,0);
        
        for(int i = 0; fill!=NULL; ++i){
            
            funcions.insert(pair<string,AST*>(fill->text,fill));
            
            //següent fill
            fill = child(defs,i);
        }
    }

    return;
}

void executarOperacions(AST *ops){
    AST *temp = child(ops,0);
    while(temp != NULL){
        
        if(temp->kind == "="){
            string id = (child(temp,0)->text).c_str();
            t_bloc b = processarBloc(child(temp,1), id);
            
            g.blocs.insert(pair<string,t_bloc>(id,b));
        }
        else if (temp->kind == "MOVE"){
            string id = (child(temp,0)->text).c_str(); //id del bloc a moure
            string dir = (child(temp,1)->kind).c_str(); //direcció cap on moure'l
            int mov = atoi((child(temp,2)->text).c_str()); //quant s'ha de moure
            
            if(dir == "NORTH"){
                (g.blocs.find(id)->second).y -= mov;;
            }
            else if(dir == "SOUTH"){
                (g.blocs.find(id)->second).y += mov;;
            }
            else if(dir == "EAST"){
                (g.blocs.find(id)->second).x += mov;
            }
            else if(dir == "WEST"){
                (g.blocs.find(id)->second).x += mov;
            }
            else cout<<"ERROR: això no és una direcció"<<endl;
        }
        else if(temp->kind == "ID"){
            //executar funcio
            executarOperacions(funcions.find(temp->text)->second);
        }            
        else if(temp->kind == "WHILE"){
            //TO-DO
        }
        else if(temp->kind == "HEIGHT"){
            string id = (child(temp,0)->text).c_str();
            t_bloc b = g.blocs.find(id)->second;
            cout<<"L'altura de "<<id<< " és "<<g.altura[b.x][b.y]<<endl;
        }
            
        else if(temp->kind == "FITS"){
            t_bloc a,b;
    
            if(child(temp,0)->kind == "list") a = processarBloc(child(temp,0),"no_id");
            else a = (g.blocs.find(child(temp,0)->text))->second;
            
            b = (g.blocs.find(child(temp,1)->text))->second;
            
            if(fun_fits(a,b)) cout <<"OK: Si que hi cap"<<endl;
            
        }
        
        //següent operacio
        temp = temp->right;
    }
}

void print(){
    d("entro print");
    int n = g.n;
    int m = g.m;
    map<string,t_bloc>::iterator i;
    vector<vector<string> > id = vector<vector<string> > (n, vector<string>(m,"[]"));
    for(i = g.blocs.begin(); i != g.blocs.end(); i++) {
        t_bloc b = i->second;
        f_id(b.x,b.y,b.w,b.h,b.id,id);
    }
    
    
    for(int j = 0; j<m; ++j){
        for(int i = 0; i<n; ++i){
            cout<<id[i][j];
        }
        cout<<endl;
    }
    cout<<endl<<endl;
    for(int j = 0; j<g.altura.size(); ++j){
        for(int i = 0; i<g.altura[j].size(); ++i){
            cout<<g.altura[i][j];
        }
        cout<<endl;
    }
    d("surto print");
}


void executeListInstrucctions(AST *a){
    
    bool hi_ha_defs = false;
    
    //graella
    
    AST *graella = child(a,0);
    //operacions
    AST *ops;
    if(child(a,1) != NULL){
        ops = child(a,1);
    }
    //definicions
    AST *defs;
    if(child(a,2)!= NULL){
        defs = child(a,2);
        hi_ha_defs = true;
    }
    
    
    
    
    //inicialitzar graella
    int n = atoi((child(graella,0)->text).c_str());
    int m = atoi((child(graella,1)->text).c_str());
    inicialitzarGraella(n,m);
    
    
    if(hi_ha_defs) processarDefinicions(defs);
    
    
    executarOperacions(ops);
    
    print();
    
}











////////////////////////////////////////////////////////////







int main() {
  root = NULL;
  ANTLR(lego(&root), stdin);
  ASTPrint(root);
  executeListInstrucctions(root);
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
place: (PLACE^ pos AT! pos);
ids: ID ( EQ^  ( place | bloc) |  ) ;
move: MOVE^ ID dir NUM;

bloc: (ID|pos) ((PUSH^|POP^) bloc| );

ops: (ids|move|height|bucle)* <<#0=createASTlist(_sibling);>>;

height: HEIGHT LP! ID RP!;
fits: FITS^ LP! ID DOT! NUM DOT! NUM DOT! NUM RP!;
cond: fits|height;
bucle: WHILE^ LP! cond RP! LC! ops RC!;

def: DEF^ ID ops ENDEF!;
defs: (def)*;

lego: grid ops defs <<#0=createASTlist(_sibling);>>;
//....