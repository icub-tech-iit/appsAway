const exec = require('node-exec-promise').exec;
const {forEach, forEachSeries, filter} = require('p-iteration')
const electron = require('electron');
const path = require('path');
const fs = require('fs');
const bashParser = require('bash-parser');

const dialog = electron.remote.dialog;


let actionBlockParameters = {}

let counter = 0;
let labelIdCounter= 0;


const createActionDiv = (text, color) => {

    let actionDiv = createElement('div', {
        classes: ['panel-item'],
        backgroundColor: color,
        activity: text
    })

    let actionDivText = createElement('span', {
        text
    })

    actionDiv.appendChild(actionDivText)

    return actionDiv
}

const addActivityDiv = (activity, modify_array = true) => {
    if (modify_array) {
        addActivity(activity);
    }   

    let actionDiv = createActionDiv(actionBlockParameters[activity].text, actionBlockParameters[activity].color);
    actionDiv.setAttribute('draggable', true);
    actionDiv.addEventListener("dragstart", moveAction); 

    if (OPTIONS.hasOwnProperty(activity)) {
        let options = createElement('img', {
            classes: ["options", "icon"],
            src: "assets/options.svg",
            shouldExpand: true,
            onClick: (event)=>{expandOrCloseOptions(event, activity)}
        })
        actionDiv.appendChild(options)
    }

    let remove = createElement('img', {
        classes: ["remove", "icon"],
        src: "assets/close.svg",
        onClick: removeActivityDiv
    })

    let optionsDiv = createElement('div', {
        classes: ["act-options"],
    })

    actionDiv.appendChild(optionsDiv)
    actionDiv.appendChild(remove)
    
    myActivitesPanel.appendChild(actionDiv);
}

const removeActivityDiv = (event) => {
    let node = findPanelItem(event.target);
    let indexToRemove = findChildIndex(node);
    removeActivity(indexToRemove)
    let parent = node.parentNode;
    parent.removeChild(node);
}

Object.keys(ACTIONS).map((actionsKey) => {
    let actionColorKeys = Object.keys(ACTIONCOLORS);
    actionBlockParameters[actionsKey] = {
        text: ACTIONS[actionsKey],
        color: ACTIONCOLORS[counter]
    }
    counter += 1
    if (counter >= ACTIONCOLORS.length) {
        counter = 0
    }
}) // actionBlockParameters = { TALK = {text: "Talk", color: "purple"}, [...] }

const allActivitesPanel = document.querySelector(".left-panel");
const myActivitesPanel = document.querySelector(".right-panel");

for (let action in actionBlockParameters) {
    let actionDiv = createActionDiv(actionBlockParameters[action].text, actionBlockParameters[action].color);
    actionDiv.onclick = ()=>{addActivityDiv(action)};
    allActivitesPanel.appendChild(actionDiv);
}

let draggedItem;

const moveAction = (event) => {
    draggedItem = event.target
}

document.addEventListener("drop", function(event) {
    let target = event.target
    if (myActivitesPanel.contains(target) && myActivitesPanel != target) { 
        let dropTarget = findPanelItem(target)
        let indexOfDropTarget = findChildIndex(dropTarget, myActivitesPanel);
        let indexOfDraggedItem = findChildIndex(draggedItem, myActivitesPanel);
        
        repositionActivity(indexOfDraggedItem, indexOfDropTarget)
        
        myActivitesPanel.innerHTML = ''

        for (let activity of activitiesToPerform) {
            addActivityDiv(activity.activity, false)
        }
    }
})

document.addEventListener("dragenter", function(event) {
    event.preventDefault()
})

document.addEventListener("dragover", function(event) {
    event.preventDefault()
})

const expandOrCloseOptions = (event, activity) => {
    if (event.target.shouldExpand == true) {
        let actionDiv = findPanelItem(event.target)
        let activityIndex = findChildIndex(actionDiv)
        let optionsDiv = actionDiv.querySelector(".act-options")
        let optionsTemplate = OPTIONS[activity]
        let specificOptions = activitiesToPerform[activityIndex].options
        optionsDiv.style.minHeight = `${30* specificOptions.length}px`
        actionDiv.style.minHeight = `${50 + 30* specificOptions.length}px`

        optionsTemplate.forEach((optionTemplate, index) => {
            let optionItem = specificOptions[index]

            let optionDiv = createElement('div', {
                maxHeight: 25
            })

            let label = createElement('span', {
                text: optionTemplate.label
            })

            optionDiv.appendChild(label)

            switch (optionTemplate.type) {
                case 'string':

                    let input = createElement('input', {
                        type: 'text',
                        defaultValue: optionItem.value,
                        onChange: (event)=>{changeActivityValue(activityIndex, index, event.target.value)}
                    })

                    optionDiv.appendChild(input)
                    break;
                case 'select':
                    
                    optionTemplate.options.forEach((radioOption) => {
                        let radioDOMOptions = {
                            type: 'radio',
                            value: radioOption,
                            name: `${optionTemplate.label}${labelIdCounter}`,
                            onClick: (event)=>{changeActivityValue(activityIndex, index, event.target.value)}
                        }
                        if (radioOption == optionItem.value) {
                            radioDOMOptions.checked = true
                        }
                        let input = createElement('input', radioDOMOptions)
                        optionDiv.appendChild(input)
                        
                        let inputLabel = createElement('span', {
                            text: radioOption
                        })
                        optionDiv.appendChild(inputLabel)
                    })

                    labelIdCounter += 1
                    break
                case 'dropdown':
                    let dropdown = createElement('select', {
                        name: `${optionTemplate.label}${labelIdCounter}`
                    })

                    optionTemplate.options.forEach((dropdownOption) => {
                        let dropdownDOMOption = createElement('option', {
                            value: dropdownOption
                        })
                        if (dropdownDOMOption.value == optionItem.value) {
                            dropdownDOMOption.selected = true
                        }
                        dropdownDOMOption.innerHTML = dropdownOption
                        dropdown.appendChild(dropdownDOMOption)
                    })

                    dropdown.addEventListener('change', (event) => {changeActivityValue(activityIndex, index, event.target.value)})

                    optionDiv.appendChild(dropdown)
                    break
                case 'float':
                    let numberInput = createElement('input', {
                        type: 'number',
                        defaultValue: optionItem.value,
                        onChange: (event)=>{changeActivityValue(activityIndex, index, event.target.value)}
                    })
                    optionDiv.appendChild(numberInput)
                    break
            }
            
            optionsDiv.appendChild(optionDiv)
            })
    } else {
        let actionDiv = findPanelItem(event.target)
        let optionsDiv = actionDiv.querySelector(".act-options")
        optionsDiv.innerHTML = ''
        optionsDiv.style.minHeight = 'fit-content'
        actionDiv.style.minHeight = '50px';
    }
    event.target.shouldExpand = !event.target.shouldExpand
}

const closeOptions = (event, activity) => {
    let actionDiv = findPanelItem(event.target)
    let optionsDiv = actionDiv.querySelector(".act-options")
    optionsDiv.innerHTML = ''
    optionsDiv.style.minHeight = 'fit-content'
}

const generateBashActionsArray = (activities) => {
    let bashActionsArray = [];
    activities.forEach((activity) => {     
          if (activity.activity == "SPEAK"){
              //for await (let options of activity.options) {​
              activity.options.forEach((options) => {
              //activity.options.forEach(async(options) => {
                if (options.label == "Text:")
                {
                  let speakStr = options.value
                  bashActionsArray.push(`${activity.activity.toLowerCase()} \"${speakStr}\"`);
                }
                if (options.label == "Wait until finish:")
                {
                  let speakWait = options.value
                  if (speakWait == "Wait")
                  {
                    bashActionsArray.push(`${speakWait.toLowerCase()}`);
                  }
                }
              })
            }
      
            if (activity.activity == "WAVE"){
              let arm = `hello_${activity.options[0].value.toLowerCase()}`
              bashActionsArray.push(arm);
            }
      
            if (activity.activity == "HOME"){
              let arm = `home_${activity.options[0].value.toLowerCase()}`
              bashActionsArray.push(arm);
            }
      
            if (activity.activity == "VICTORY"){
              let arm = `victory_${activity.options[0].value.toLowerCase()}`
              bashActionsArray.push(arm);
            }
            
            if (activity.activity == "EMOTION"){
              let emotion = activity.options[0].value.toLowerCase()
              bashActionsArray.push(emotion);
            }
            if (activity.activity == "FONZIE"){
              bashActionsArray.push('fonzie')
            }
        });
    return bashActionsArray;
} 

const runDemo = async() => {
    run = true;
    let bashActions = generateBashActionsArray(activitiesToPerform);

    await forEachSeries(bashActions, async (bashAction) => {
        let out = await exec(`../script/funnythings.sh ${bashAction}`)
    })
}

const stopDemo = () => {
    run = false
}


const clearAll = () => {
    clearActivities()
    myActivitesPanel.innerHTML = ''
}

const generateFullFilename = (filename) => {
    let filenameArray = filename.split('.');
    if (filenameArray.length == 1 || filenameArray[filenameArray.length - 1] !== 'funnythings') {
        return filename + '.funnythings'
    } else {
        return filename
    }
}

const exportActivities = () => {
    saveTextFile(JSON.stringify(activitiesToPerform, null, 2),
    'Save your activites',
    '~/mydemo.funnythings',
    'Save',
    'Funny Things Demos',
    ['funnythings'])
}

const importActivities = () => {
    dialog.showOpenDialog({ 
        properties: ['openFile'],
        buttonLabel: 'Load',
        filters: [
            {
                name: 'Funny Things Demos',
                extensions: ['funnythings']
            }
        ]
    }).then(file => {
        if (!file.canceled) {
            fs.readFile(file.filePaths.toString(), 'utf8', (err, data) => {
                if (err) throw err;
                let parsedData = JSON.parse(data);
                console.log(checkActivites(parsedData) ? 'Valid input' : 'There is something wrong')
                if (checkActivites(parsedData)) {
                    activitiesToPerform = parsedData;
                    console.log('Imported!')
                    myActivitesPanel.innerHTML = ''
                    for (let activity of activitiesToPerform) {
                        addActivityDiv(activity.activity, false)
                    }
                }
            });
        }
    }).catch(err => {
        console.log(err)
    })
}

const saveTextFile = (textContent, title, defaultPath, buttonLabel, filterName, extensions) => {
    dialog.showSaveDialog({
        title,
        defaultPath,
        buttonLabel,
        filters: [
            {
                name: filterName,
                extensions
            }
        ]
    }).then(file => {
        if (!file.canceled) {    
            fs.writeFile(file.filePath.toString(), textContent, function (err) {
                if (err) throw err;
                console.log('Saved!')
            })
        }
    }).catch(err => {
        console.log(err)
    })
}

const bashParserThings = ()=>{
    let actionsArray = generateBashActionsArray(activitiesToPerform);
    fs.readFile('../script/funnythings_template.sh', 'utf8', (err, data) => {
        let newFunnyThingScriptContent = data;
        actionsArray.forEach((action) => {
            newFunnyThingScriptContent += action + '\n'
        })
        saveTextFile(newFunnyThingScriptContent,
                        'Save your bash script',
                        '~/mydemoscript.sh',
                        'Save',
                        'Shell scripts',
                        ['sh']);
    })
}