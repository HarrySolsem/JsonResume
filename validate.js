    const fs = require('fs');

     fs.readFile('resume.json', 'utf8', (err, data) => {
       if (err) {
         console.error('Error reading file:', err);
         return;
       }
       try {
         const json = JSON.parse(data);
         console.log('Valid JSON:', json);
       } catch (parseErr) {
         console.error('Invalid JSON:', parseErr.message);
       }
     });