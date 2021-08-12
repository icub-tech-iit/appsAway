const exec = require('child_process').exec;

const OPTIONS = {
    TALK: [
        {
            type: "string",
            label: "Text:",
            default_value: ""
        },
        {
            type: "select",
            label: "Wait until finish:",
            options: [
                "Wait",
                "Don't wait"
            ],
            default_value: 0
        }
    ],
    WAVE: [
        {
            type: "select",
            label: "Arm(s):",
            options: [
                "Left",
                "Right",
                "Both"
            ],
            default_value: 1
        }
    ],
    SLEEP: [
        {
            type: "string",
            label: "Time:",
            default_value: "0"
        }
    ],
    EMOTION: [
        {
            type: "select",
            label: "Emotion:",
            options: [
                "Happy",
                "Sad",
                "Angry",
                "Suspicious"
            ],
            default_value: 0
        }
    ]
}

const ACTIONS = {
    TALK: "Talk",
    WAVE: "Wave",
    GRASP: "Grasp an object",
    EMOTION: "Display an Emotion",
    EXTERMINATE: "Exterminate human race",
    KICK: "Kick",
    SLEEP: "Sleep"
}

const ACTIONCOLORS = ["ed8931","73556e","f07f56","d97373"]


let activitiesToPerform = [];

let actionBlockParameters = {}

let counter = 0;

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

const allActivitesPanel = document.querySelector(".right-panel");
const myActivitesPanel = document.querySelector(".left-panel");

let draggedItem;

document.addEventListener("drop", function(event) {
    let target = event.target
    if (myActivitesPanel.contains(target)) { 
        let dropTarget = target.closest(".panel-item")
        let indexOfDropTarget = Array.from(myActivitesPanel.children).indexOf(dropTarget);
        let indexOfDraggedItem = Array.from(myActivitesPanel.children).indexOf(draggedItem);
        
        activitiesToPerform.splice(indexOfDropTarget, 0, activitiesToPerform.splice(indexOfDraggedItem, 1)[0])
        
        myActivitesPanel.innerHTML = ''

        for (let activity of activitiesToPerform) {
            addActivity(activity, false)
        }
    }
    console.log("drop")
})

document.addEventListener("dragenter", function(event) {
    event.preventDefault()
})

document.addEventListener("dragover", function(event) {
    event.preventDefault()
})

const createActionDiv = (text, color) => {
    let actionDiv = document.createElement('div');
    actionDiv.classList.add('panel-item');
    actionDiv.style.backgroundColor = `#${color}`
    let actionDivText = document.createElement('span');
    actionDivText.textContent = text;
    actionDiv.appendChild(actionDivText);
    actionDiv.activity = text;
    return actionDiv
}

const removeActivity = (event) => {
    let node = event.target.closest(".panel-item");
    let parent = node.parentNode;
    let indexToRemove = Array.from(parent.children).indexOf(node);
    activitiesToPerform.splice(indexToRemove, 1);
    parent.removeChild(node);
}

const moveAction = (event) => {
    draggedItem = event.target
}

const expandOptions = (event, activity) => {
    let actionDiv = event.target.closest(".panel-item")
    let optionsDiv = actionDiv.querySelector(".act-options")
    let specificOptions = OPTIONS[activity]
    optionsDiv.style.minHeight = `${25 * OPTIONS[activity].length}px`
    for (let option of specificOptions) {
        let optionDiv = document.createElement('div')
        optionDiv.style.maxHeight = '25px'
        let label = document.createElement('span')
        label.textContent = option.label
        optionDiv.appendChild(label)

        switch (option.type) {
            case 'string':
                let input = document.createElement('input')
                input.type = 'text'
                input.defaultValue = option.default_value
                optionDiv.appendChild(input)
                break;
        }
        
        optionsDiv.appendChild(optionDiv)
    }
}

const addActivity = (activity, modify_array = true) => {
    let actionDiv = createActionDiv(actionBlockParameters[activity].text, actionBlockParameters[activity].color);
    options = document.createElement('img')
    if (Object.keys(OPTIONS).includes(activity)) {
        options.classList.add("options", "icon")
        options.src = "assets/options.svg"
        options.addEventListener("click", (event)=>{expandOptions(event, activity)})
        actionDiv.appendChild(options)
    }
    remove = document.createElement('img')
    remove.classList.add("remove", "icon")
    remove.src = "assets/close.svg"
    remove.addEventListener('click', removeActivity);
    let optionsDiv = document.createElement('div')
    optionsDiv.classList.add("act-options")
    actionDiv.appendChild(optionsDiv)
    actionDiv.appendChild(remove)
    actionDiv.setAttribute('draggable', true);
    actionDiv.addEventListener("dragstart", moveAction);
    if (modify_array) {
        activitiesToPerform.push(activity);
    }    
    myActivitesPanel.appendChild(actionDiv);
}

for (let action in actionBlockParameters) {
    let actionDiv = createActionDiv(actionBlockParameters[action].text, actionBlockParameters[action].color);
    actionDiv.onclick = ()=>{addActivity(action)};
    allActivitesPanel.appendChild(actionDiv);
}

const runDemo = () => {
    let str = "\"this is a test\""
    activitiesToPerform.forEach((activity) => {
      exec(`../script/funnythings.sh ${activity.toLowerCase()} ${str}`, (err,stdout,stderr)=>{
      //exec(`/training/electron/${activity.toLowerCase()}.sh`, (err,stdout,stderr)=>{
            console.log(`${activity} err: ${err}`);
            console.log(`${activity} stdout: ${stdout}`);
            console.log(`${activity} stderr: ${stderr}`);
        });
    })
}
