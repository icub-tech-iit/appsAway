
const {app, BrowserWindow} = require('electron');
const path = require('path');
const url = require('url');

function createWindow(){
    //Create browser window
    const mainWindow = new BrowserWindow({
        width: 1000,
        height: 700,
        minHeight: 700,
        minWidth: 1000,
        webPreferences: {
            nodeIntegration: true, 
            contextIsolation: false,
            devTools: false,
            enableRemoteModule: true,
            preload: path.join(__dirname, 'preload.js')
        }
    })

    // Uncomment if you want to set a fixed window size
    // mainWindow.setResizable(false);
    // mainWindow.setMaximizable(false);
    mainWindow.setMenu(null);

    mainWindow.setIcon(path.join(__dirname, 'assets/icon.png'));

    // Load index.html
    mainWindow.loadFile('index.html')
    // open devtools
    // mainWindow.webContents.openDevTools();
}

app.whenReady().then(() => {
    createWindow()
    app.on('activate', function () {
        // On macOS it's common to re-create a window in the app when the
        // dock icon is clicked and there are no other windows open.
        if (BrowserWindow.getAllWindows().length === 0) createWindow()
    })
})

// Quit when all windows are closed

app.on('window-all-closed', () => {
    if(process.platform == 'darwin') app.quit();
})



