#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include "parse.h"
#include "parser.h"
#include "../query_node.h"

/* forward declarations of stuff generated by lemon */
void Parse(void *yyp, int yymajor, QueryToken yyminor, parseCtx *ctx);
void *ParseAlloc(void *(*mallocProc)(size_t));
void ParseFree(void *p, void (*freeProc)(void *));

%%{

machine query;

inf = ['+\-']? 'inf' $ 3;
number = '-'? digit+('.' digit+)? $ 2;

quote = '"';
or = '|';
lp = '(';
rp = ')';
colon = ':';
minus = '-';
tilde = '~';
star = '*';
rsqb = ']';
lsqb = '[';
mod = '@'.alpha.(alnum | '_')* $ 1;
term = ((any - punct - cntrl - space) | '_')+  $ 0 ;

main := |*

  number => { 
    tok.s = ts;
    tok.len = te-ts;
    char *ne = (char*)te;
    tok.numval = strtod(tok.s, &ne);
    tok.pos = ts-q->raw;
    Parse(pParser, NUMBER, tok, &ctx);
    if (!ctx.ok) {
      fbreak;
    }
    
  };
  mod => {
    tok.pos = ts-q->raw;
    tok.len = te - (ts + 1);
    tok.s = ts+1;
    Parse(pParser, MODIFIER, tok, &ctx);
    if (!ctx.ok) {
      fbreak;
    }
  };
  inf => { 
    tok.pos = ts-q->raw;
    tok.s = ts;
    tok.len = te-ts;
    
    tok.numval = *ts == '-' ? -INFINITY : INFINITY;
    Parse(pParser, NUMBER, tok, &ctx);
    if (!ctx.ok) {
      fbreak;
    }
  };
  
  quote => {
    tok.pos = ts-q->raw;
    Parse(pParser, QUOTE, tok, &ctx);  
    if (!ctx.ok) {
      fbreak;
    }
  };
  or => { 
    tok.pos = ts-q->raw;
    Parse(pParser, OR, tok, &ctx);
    if (!ctx.ok) {
      fbreak;
    }
  };
  lp => { 
    tok.pos = ts-q->raw;
    Parse(pParser, LP, tok, &ctx);
    if (!ctx.ok) {
      fbreak;
    }
  };
  rp => { 
    tok.pos = ts-q->raw;
    Parse(pParser, RP, tok, &ctx);
    if (!ctx.ok) {
      fbreak;
    }
  };
   colon => { 
     tok.pos = ts-q->raw;
     Parse(pParser, COLON, tok, &ctx);
     if (!ctx.ok) {
      fbreak;
    }
   };

  minus =>  { 
    tok.pos = ts-q->raw;
    Parse(pParser, MINUS, tok, &ctx);  
    if (!ctx.ok) {
      fbreak;
    }
  };
  tilde => { 
    tok.pos = ts-q->raw;
    Parse(pParser, TILDE, tok, &ctx);  
    if (!ctx.ok) {
      fbreak;
    }
  };
  star => { 
    tok.pos = ts-q->raw;
    Parse(pParser, STAR, tok, &ctx);    
    if (!ctx.ok) {
      fbreak;
    }
  }; 
  lsqb => { 
    tok.pos = ts-q->raw;
    Parse(pParser, LSQB, tok, &ctx);  
    if (!ctx.ok) {
      fbreak;
    }  
  };
  rsqb => { 
    tok.pos = ts-q->raw;
    Parse(pParser, RSQB, tok, &ctx);   
    if (!ctx.ok) {
      fbreak;
    } 
  };
  space;
  punct;
  cntrl;
  term => {
    tok.len = te-ts;
    tok.s = ts;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    if (!isStopword(tok.s, tok.len, q->stopwords)) {
        Parse(pParser, TERM, tok, &ctx);
    } 
    if (!ctx.ok) {
      fbreak;
    }
  };
  
*|;
}%%

%% write data;



QueryNode *Query_Parse(Query *q, char **err) {
  void *pParser = ParseAlloc(malloc);

  
  int cs, act;
  const char* ts = q->raw;
  const char* te = q->raw + q->len;
  %% write init;
  QueryToken tok = {};
  
  parseCtx ctx = {.root = NULL, .ok = 1, .errorMsg = NULL, .q = q};
  const char* p = q->raw;
  const char* pe = q->raw + q->len;
  const char* eof = pe;
  
  %% write exec;
  

  if (ctx.ok) {
    Parse(pParser, 0, tok, &ctx);
  }
  ParseFree(pParser, free);
  if (err) {
    *err = ctx.errorMsg;
  }

  if (ctx.root) {
    q->root = ctx.root;
  }
  return ctx.root;
}

