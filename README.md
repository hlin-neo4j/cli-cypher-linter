# Cypher Syntax Checker CLI
Leverages the grammar and antlr4 source code from the cypher-editor (https://github.com/neo4j/cypher-editor) project, credit to them. A work in progress for something I hope to rewrite as an actual vscode extension for Cypher highlighting and syntax checking.

# To run as a user prompt:
`npm run start`
Then enter a cypher query lint check it.

# Antlr
(Credit to cypher-editor) To generate the antlr lexer and parser files, run `npm run generate`.