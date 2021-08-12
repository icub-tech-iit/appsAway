// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// No Node.js APIs are available in this process because
// `nodeIntegration` is turned off. Use `preload.js` to
// selectively enable features needed in the rendering
// process.
const exec = require('child_process').exec;

function getData(){
    console.log('Called!!!');
    // call the function
    execute('ls', (output) => {
        console.log(output);
    });
  }

  function execute(command, callback) {
    exec(command, (error, stdout, stderr) => { 
        callback(stdout); 
    });
  };

  //document.querySelector('#btnEd').addEventListener('click', () => {
  //  getData()
  //})