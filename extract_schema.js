const fs = require('fs');
const path = require('path');
const dir = 'c:/SEMESTER 4/PAA/APIPBM/MedfastAPI/src/controllers';
const files = fs.readdirSync(dir);
const tables = {};

files.forEach(file => {
  const content = fs.readFileSync(path.join(dir, file), 'utf-8');
  let match;
  
  const fromRegex = /\.from\(['"]([^'"]+)['"]\)([\s\S]*?)(?=;|\.from|$)/g;
  while ((match = fromRegex.exec(content)) !== null) {
    const table = match[1];
    if (!tables[table]) tables[table] = { columns: new Set(), select: new Set(), insert: new Set(), update: new Set() };
    const queryChain = match[2];
    
    // find select
    const selectMatch = queryChain.match(/\.select\(['"]([^'"]+)['"]\)/);
    if (selectMatch) {
      selectMatch[1].split(',').map(s=>s.trim().split('(')[0]).forEach(c => {
         if(c !== '*') tables[table].select.add(c);
      });
    }

    // find insert
    const insertMatch = queryChain.match(/\.insert\(([\s\S]*?)\)/);
    if (insertMatch) {
       const keys = [...insertMatch[1].matchAll(/([a-zA-Z0-9_]+)\s*:/g)].map(m => m[1]);
       keys.forEach(k => tables[table].insert.add(k));
    }
    
    // find update
    const updateMatch = queryChain.match(/\.update\(([\s\S]*?)\)/);
    if (updateMatch) {
       const keys = [...updateMatch[1].matchAll(/([a-zA-Z0-9_]+)\s*:/g)].map(m => m[1]);
       keys.forEach(k => tables[table].update.add(k));
    }

    // find eq
    const eqMatches = [...queryChain.matchAll(/\.eq\(['"]([^'"]+)['"]/g)];
    eqMatches.forEach(m => tables[table].columns.add(m[1]));
  }
});

for (let t in tables) {
   console.log('TABLE: ' + t);
   console.log('  Columns from eq():', [...tables[t].columns].join(', '));
   console.log('  Columns from select():', [...tables[t].select].join(', '));
   console.log('  Columns from insert():', [...tables[t].insert].join(', '));
   console.log('  Columns from update():', [...tables[t].update].join(', '));
}
