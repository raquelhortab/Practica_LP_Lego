#header
<<
#include <string>
#include <iostream>
#include <sstream>
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
    int a;
}t_bloc;

typedef struct{
    int n,m;
    vector<vector<int> > altura;
    map<string, t_bloc> blocs;
}Graella;


Graella g;

map<string,AST*> funcions; //mapa de les funcions DEF 


///declaració de funcions
t_bloc processarBloc(AST *a, string id);
bool fun_fits(t_bloc a, t_bloc b);
t_bloc push(AST *a1, AST *a2);
t_bloc pop(AST *a1, AST *a2);
int altura(int x, int y, int w, int h);
void id(int x, int y, int w, int h,string s_id,vector<vector<string> > vec_id);
void processarDefinicions(AST *defs);
bool fun_fits(t_bloc a, t_bloc b, int alt);
bool fun_fits(t_bloc b, int x, int y);

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





int altura(int x, int y, int w, int h){
    for(int i = x; i < x+w; ++i){
        for(int j = y; j < y+h; ++j){
            ++g.altura[i][j];
        }
    }
    return g.altura[x][y];
}
int resta_altura(int x, int y, int w, int h){
    for(int i = x; i < x+w; ++i){
        for(int j = y; j < y+h; ++j){
            --g.altura[i][j];
        }
    }
    return g.altura[x][y];
}


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
        
        if(fun_fits(b,(b.x),(b.y))){
            b.a=altura(b.x,b.y,b.w,b.h);
            cout << "OK: PLACE de "<<b.id<<endl;
            return b;
        }
        else{
            cout << "ERROR: no hi cap "<<b.id<<endl;
            b.id = "ERROR";
            return b;
        }
        
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
        AST *a1 = child(a,0);
        AST *a2 = child(a,1);
        t_bloc resultat = push(a1,a2);
        return resultat;
    }
    else if(a->kind == "POP"){
        AST *a1 = child(a,0);
        AST *a2 = child(a,1);
        t_bloc resultat = pop(a1,a2);
        return resultat;
    }
    
    cout<<"ERROR: no és un bloc a processar"<<endl;
    t_bloc null;
    null.id="NULL";
    return null;
}

bool fun_fits(t_bloc a, t_bloc b, int &x, int &y){
    int cont = 0;
    int alt = g.altura[b.x][b.y];


    if((a.x > b.x) or (a.y > b.y)) return false;
    
    bool stop = false;
    bool trobat = false;
    //recorrer tot el bloc b, on serà col·locat el bloc a
    for(int j = b.y; j <= (b.y + b.h) and not trobat; ++j){
        for(int i = b.x; i <= (b.x + b.w) and not trobat; ++i){
            ++cont;
            //si s'ha trobat espai horitzontal
            if((a.w == 1) or (cont == a.w and g.altura[i][j] == alt) ){
                //mirar si hi cap el bloc senser
                alt = g.altura[i][j];
                for(int k = i-(a.w -1); k <= i and not stop; ++k){
                    for(int l = j; l < j+a.h and not stop; ++l){
                        if(g.altura[k][l] != alt)stop = true;
                    }
                }
                if(not stop){
                    x = i-(a.w -1);
                    y = j;
                    return true;
                }
                stop = false;
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

bool fun_fits(t_bloc a, t_bloc b, int alt){
    int cont = 0;


    if((a.w > b.w) or (a.h > b.h)) return false;
    
    bool stop = false;
    bool trobat = false;
    //recorrer tot el bloc b, on serà col·locat el bloc a
    for(int j = b.y; j <= (b.y + b.h) and not trobat; ++j){
        for(int i = b.x; i <= (b.x + b.w) and not trobat; ++i){
            ++cont;
            
           
            if(g.altura[i][j] != alt){ //si l'altura és diferent
                cont = 0;

            }
            else if(i == (b.x + b.w)) cont == 0; //si arriba a la vora dreta
            //si s'ha trobat espai horitzontal
            else if((a.w == 1) or (cont == a.w and g.altura[i][j] == alt) ){
                //mirar si hi cap el bloc senser
                
                for(int k = i-(a.w -1); k <= i and not stop; ++k){
                    for(int l = j; l < j+a.h and not stop; ++l){
                        if(g.altura[k][l] != alt)stop = true;
                    }
                }
                if(not stop){

                    return true;
                }
                stop = false;
            }
        }
    }
    return false;
}

bool fun_fits(t_bloc b, int x, int y){
    int alt = g.altura[x][y];
    int w = b.w;
    int h = b.h;
    for(int i = x; i < x+b.w; ++i){
        for(int j = y; j < y+b.h; ++j){
            if(g.altura[i][j] != alt) return false;
        }
    }
    return true;
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
    int x,y;
    if(fun_fits(a,b,x,y)){
        //g.blocs.insert(pair<string,t_bloc>(a.id,a));
        //modificar l'altura
        if(a.id != "no_id") {
            resta_altura(a.x,a.y,a.w,a.h);
        }
        ((g.blocs.find(a1->text))->second).x = x;
        ((g.blocs.find(a1->text))->second).y = y;
        ((g.blocs.find(a1->text))->second).a += (g.blocs.find(a2->text)->second).a;
        a.x = x;
        a.y = y;
        altura(a.x,a.y,a.w,a.h);
        //g.blocs.erase(a.id);
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
    
    resta_altura(a.x,a.y,a.w,a.h);
    //eliminem el bloc
    g.blocs.erase(a.id);
    cout << "OK: POP de "<<a.id<<" de "<<b.id<<endl;
    return b;
}



void f_id(int x, int y, int w, int h,string s_id,vector<vector<string> > &vec_id){
    t_bloc a = g.blocs.find(s_id)->second;
    t_bloc b;
    for(int i = x; i < x+w; ++i){
        for(int j = y; j < y+h; ++j){
            b = g.blocs.find(vec_id[i][j])->second;
            if(vec_id[i][j]=="[]") vec_id[i][j] = s_id;
            else if(a.a > b.a) vec_id[i][j] = s_id;
        }
    }
}


void processarDefinicions(AST *defs){

    //recorrer tots els fills i guardar al map de funcions
    while(defs != NULL){
        string id = child(defs,0)->text;
        AST *op = child(defs,1);
        funcions.insert(pair<string,AST*>(id,op));
        defs = defs->right;
    }

    return;
}

bool condicio(AST *cond){
        if(cond->kind == "FITS"){
            
            t_bloc objectiu = g.blocs.find(child(cond,0)->text)->second;
            int w = atoi((child(cond,1)->text).c_str());
            int h = atoi((child(cond,2)->text).c_str());
            int a = atoi((child(cond,3)->text).c_str());
            
            t_bloc victima;
            victima.w = w;
            victima.h = h;
            victima.id = "no_id";

            if(fun_fits(victima,objectiu,a)) return true;
            return false;
        }
        else if(cond->kind == ">"){
            string id = (child(child(cond,0),0)->text).c_str(); //id bloc
            int num = atoi((child(cond,1)->text).c_str()); //numero a comparar
            t_bloc b = g.blocs.find(id)->second;
            int alt = g.altura[b.x][b.y];
            if(alt > num) return true;
            return false;
        }
        else if(cond->kind == "<"){
            string id = (child(child(cond,0),0)->text).c_str(); //id bloc
            int num = atoi((child(cond,1)->text).c_str()); //numero a comparar
            t_bloc b = g.blocs.find(id)->second;
            int alt = g.altura[b.x][b.y];
            if(alt < num) return true;
            return false;
        }
        else if(cond->kind == ">="){
            string id = (child(child(cond,0),0)->text).c_str(); //id bloc
            int num = atoi((child(cond,1)->text).c_str()); //numero a comparar
            t_bloc b = g.blocs.find(id)->second;
            int alt = g.altura[b.x][b.y];
            if(alt >= num) return true;
            return false;
        }
        else if(cond->kind == "<="){
            string id = (child(child(cond,0),0)->text).c_str(); //id bloc
            int num = atoi((child(cond,1)->text).c_str()); //numero a comparar
            t_bloc b = g.blocs.find(id)->second;
            int alt = g.altura[b.x][b.y];
            if(alt <= num) return true;
            return false;
        }
        else if(cond->kind == "=="){
                string id = (child(child(cond,0),0)->text).c_str(); //id bloc
                int num = atoi((child(cond,1)->text).c_str()); //numero a comparar
                t_bloc b = g.blocs.find(id)->second;
                int alt = g.altura[b.x][b.y];
                if(alt == num) return true;
                return false;
            }
}

void executarOperacions(AST *ops){
    AST *temp = child(ops,0);
    while(temp != NULL){
        
        if(temp->kind == "="){
            string id = (child(temp,0)->text).c_str();
            t_bloc b = processarBloc(child(temp,1), id);
            if(b.id != "ERROR")g.blocs.insert(pair<string,t_bloc>(id,b));
        }
        else if (temp->kind == "MOVE"){
            string id = (child(temp,0)->text).c_str(); //id del bloc a moure
            string dir = (child(temp,1)->kind).c_str(); //direcció cap on moure'l
            int mov = atoi((child(temp,2)->text).c_str()); //quant s'ha de moure
            t_bloc temp = g.blocs.find(id)->second;
            resta_altura(temp.x,temp.y,temp.w,temp.h);
            
            if(dir == "NORTH"){
                int p = (g.blocs.find(id)->second).y - mov;
                if(p > 0) {
                    (g.blocs.find(id)->second).y -= mov;
                    cout<<"OK: MOVE de "<<id<<endl;
                }
                else cout<<"ERROR: "<<id<<" Sortiria de la graella"<<endl;
            }
            else if(dir == "SOUTH"){
                int p = (g.blocs.find(id)->second).y + mov;
                if(p<g.m){
                    (g.blocs.find(id)->second).y += mov;
                    cout<<"OK: MOVE de "<<id<<endl;
                }
                else cout<<"ERROR: "<<id<<" Sortiria de la graella"<<endl;
            }
            else if(dir == "EAST"){
                int p = (g.blocs.find(id)->second).x + mov;
                if(p<g.n) {
                    (g.blocs.find(id)->second).x += mov;
                    cout<<"OK: MOVE de "<<id<<endl;
                }
                else cout<<"ERROR: "<<id<<" Sortiria de la graella"<<endl;
            }
            else if(dir == "WEST"){
                int p = (g.blocs.find(id)->second).x - mov;
                if(p>0) {
                    (g.blocs.find(id)->second).x -= mov;
                    cout<<"OK: MOVE de "<<id<<endl;
                }
                else cout<<"ERROR: "<<id<<" Sortiria de la graella"<<endl;
            }
            else cout<<"ERROR: això no és una direcció"<<endl;
            
            temp = g.blocs.find(id)->second;
            altura(temp.x,temp.y,temp.w,temp.h);
            
        }
        else if(temp->kind == "ID"){
            //executar funcio
            cout<<"FUNCIÓ: s'aplicarà "<<temp->text<<endl;
            executarOperacions(funcions.find(temp->text)->second);
            cout<<"FUNCIÓ: s'ha aplicat "<<temp->text<<endl;
        }            
        else if(temp->kind == "WHILE"){
            AST *cond = child(temp,0);
            AST *oper = child(temp,1);
            if(cond->kind == "AND"){
                AST *fill = child(cond,0);
                bool t = true;
                while(fill != NULL and t){
                    t = t and condicio(fill);
                }
                while(t){
                    executarOperacions(oper);
                    fill = child(cond,0);
                    t = true;
                    while(fill != NULL and t){
                        t = t and condicio(fill);
                    }
                }
            }
            else {
                bool b = condicio(cond);
                while(b){
                    executarOperacions(oper);
                    b = condicio(cond);
                }
            }
        }
        else if(temp->kind == "HEIGHT"){
            string id = (child(temp,0)->text).c_str();
            t_bloc b = g.blocs.find(id)->second;
            cout<<"L'altura de "<<id<< " és "<<g.altura[b.x][b.y]<<endl;
        }
            
        else if(temp->kind == "FITS"){
            
            t_bloc objectiu = g.blocs.find(child(temp,0)->text)->second;
            int w = atoi((child(temp,1)->text).c_str());
            int h = atoi((child(temp,2)->text).c_str());
            int a = atoi((child(temp,3)->text).c_str());
            
            t_bloc victima;
            victima.w = w;
            victima.h = h;
            victima.id = "no_id";
            
            if(fun_fits(victima,objectiu,a)) cout <<"SI QUE HI CAP"<<endl;
            else cout<<"NO HI CAP"<<endl;
            
        }
        
        //següent operacio
        temp = temp->right;
    }
}

void print(){
    int n = g.n;
    int m = g.m;
    map<string,t_bloc>::iterator i;
    vector<vector<string> > id = vector<vector<string> > (n, vector<string>(m,"[]"));
    
    for( int i = 0; i < id[0].size(); ++i){
        ostringstream oss;
        oss<<i;
        if(i<10) oss <<" ";
        id[0][i] = oss.str();
    }
    for( int i = 0; i < id.size(); ++i){
        ostringstream oss;
        oss<<i<<" ";
        id[i][0] = oss.str();
    }
    
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
    
    //altura print
    
    for( int i = 0; i < g.altura[0].size(); ++i){
        g.altura[0][i] = i;
    }
    for( int i = 0; i < g.altura.size(); ++i){
        g.altura[i][0] = i;
    }
    
    for(int j = 0; j<g.altura[0].size(); ++j){
        for(int i = 0; i<g.altura.size(); ++i){
            cout<<g.altura[i][j]<<" ";
            if(i == 0 and j<10) cout <<" ";
        }
        cout<<endl;
    }

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
    inicialitzarGraella(n+1,m+1);
    
    
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
#token POP "POP"
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

ops: (ids|move|height|fits|bucle)* <<#0=createASTlist(_sibling);>>;

height: HEIGHT^ LP! ID RP!;
fits: FITS^ LP! ID DOT! NUM DOT! NUM DOT! NUM RP! ;
cond: fits|height;
bucle: WHILE^ LP! cond RP! LC! ops RC!;

def: DEF^ ID ops ENDEF!;
defs: (def)*;

lego: grid ops defs <<#0=createASTlist(_sibling);>>;
//....