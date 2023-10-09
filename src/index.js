#!/usr/bin/env node

import {CypherParser, CypherLexer} from './lang/index.js'
import antlr4 from 'antlr4'
import { createInterface } from 'readline';

async function main() {
  while (true) {
    const qry = await readlineAsync("Enter a Cypher query (empty to exit) > ");
    if (qry === '') {
      rl.close();
      break;
    }
    const errorListener = new MyErrorListener();
    const chars = new antlr4.InputStream(qry);
    const lexer = new CypherLexer(chars)
    lexer.removeErrorListeners();
    lexer.addErrorListener(errorListener);
    
    const tokens = new antlr4.CommonTokenStream(lexer);
    const parser = new CypherParser(tokens);
    parser.buildParseTrees = true;
    
    parser.removeErrorListeners();
    parser.addErrorListener(errorListener);
    const parseTree = parser.cypher()
    
    console.log('\n\n\n');
    if (!errorListener.errors || !errorListener.errors.length) {
      console.log('Syntax checks out!');
      continue;
    }
    
    for (let error of errorListener.errors) {
        console.log(error.msg);
        console.log('\n')
    }
  }
}

const rl = createInterface({
  input: process.stdin,
  output: process.stdout
});

const readlineAsync = msg => {
  return new Promise(resolve => {
      rl.question(msg, userRes => {
          resolve(userRes);
      });
  });    
}

class MyErrorListener extends antlr4.error.ErrorListener {
  errors = [];

  // eslint-disable-next-line no-unused-vars
  syntaxError(rec, sym, line, col, msg, e) {
    const { start, stop } = sym || {};
    console.log('msg', msg)
    if (msg === "mismatched input '<EOF>' expecting {';', SP}") {
      // suppress error about missing semicolon at the end of a query
      return;
    }
    if (msg === "missing ';' at '<EOF>'") {
      return;
    }
    if (
      msg ===
      "mismatched input '<EOF>' expecting {':', CYPHER, EXPLAIN, PROFILE, USING, CREATE, DROP, LOAD, WITH, OPTIONAL, MATCH, UNWIND, MERGE, SET, DETACH, DELETE, REMOVE, FOREACH, RETURN, START, CALL}"
    ) {
      return;
    }
    this.errors.push({ line, col, msg, start, stop });
  }
}

main();