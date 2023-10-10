#!/usr/bin/env node

import {CypherParser, CypherLexer} from './lang/index.js'
import antlr4 from 'antlr4'
import { createInterface } from 'readline';
import fs from 'fs/promises'
import { exit } from 'process';

async function main() {
  if (process.argv.length === 2) {
    // PROMPT
    while (true) {
      const qry = await readlineAsync("Enter a Cypher query (empty to exit) > ");
      runEvaluation(qry);
      rl.close();
    }
  } else {
    // FILE
    const filepath = process.argv[2];
    const data = await fs.readFile(filepath, { encoding: 'utf8' });
    runEvaluation(data);
  }

  exit(0);
}

function runEvaluation(qry) {
  if (qry === '') {
    console.log('Empty string')
    return;
  }
  
  const errorListener = new MyErrorListener();
  const chars = new antlr4.InputStream(qry);
  const lexer = new CypherLexer(chars)
  lexer.removeErrorListeners();
  lexer.addErrorListener(errorListener);
  
  const parser = new CypherParser(new antlr4.CommonTokenStream(lexer));
  parser.buildParseTrees = true;
  
  parser.removeErrorListeners();
  parser.addErrorListener(errorListener);
  const parseTree = parser.cypher()
  
  if (!errorListener.errors || !errorListener.errors.length) {
    console.log('No errors');
    return;
  }
  
  // for (let error of errorListener.errors) {
  //     // console.log(error.msg);
  //     console.log('\n')
  // }
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