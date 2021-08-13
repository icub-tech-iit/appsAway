const exec = require('node-exec-promise').exec;
//const {​​​ forEach }​​​ = require('p-iteration')

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

const runDemo = async() => {
     
    activitiesToPerform.forEach(async(activity) => {

      console.log( activity.activity.toLowerCase() );     
      //if (activity.hasOwnProperty("options") )
      if (activity.activity == "SPEAK"){

        for await (let options of activity.options) {
        //activity.options.forEach(async(options) => {
          if (options.label == "Text:")
          {
            let speakStr = options.value
            let out = await exec(`../script/funnythings.sh ${activity.activity.toLowerCase()} \"${speakStr}\"`);
            console.log(out)
          }
          if (options.label == "Wait until finish:")
          {
            let speakWait = options.value
            if (speakWait == "Wait")
            {
              console.log("in wait")
              let out = await exec(`../script/funnythings.sh ${speakWait.toLowerCase()}`);
              
              console.log("Finished")
            }
          }
        }//)
      }
      if (activity.activity == "WAVE"){
        let arm = `hello_${activity.options[0].value.toLowerCase()}`
        let out = await exec(`../script/funnythings.sh ${arm}`);
      }
      if (activity.activity == "EMOTION"){
        let emotion = activity.options[0].value.toLowerCase()
        let out = await exec(`../script/funnythings.sh ${emotion}`);
      }
    })
}


const clearAll = () => {
    clearActivities()
    myActivitesPanel.innerHTML = ''
}