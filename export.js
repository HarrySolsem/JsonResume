     const puppeteer = require('puppeteer');
     const fs = require('fs');

     (async () => {
       const browser = await puppeteer.launch();
       const page = await browser.newPage();

       // Load your JSON data
       const resumeData = JSON.parse(fs.readFileSync('resume.json', 'utf8'));

       // Convert JSON to HTML (use your own template)
       const htmlContent = `
         <html>
           <head><title>${resumeData.basics.name}'s Resume</title></head>
           <body>
             <h1>${resumeData.basics.name}</h1>
             <p>${resumeData.basics.summary}</p>
             <!-- Add more sections here -->
           </body>
         </html>
       `;

       await page.setContent(htmlContent);
       await page.pdf({ path: 'resume.pdf', format: 'A4' });

       await browser.close();
     })();
     