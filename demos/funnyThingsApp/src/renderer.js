const exec = require('child_process').exec;

const ACTIONS = {
    TALK: "Talk",
    HELLO_LEFT: "hello_left",
    GRASP: "Grasp an object",
    SMILE: "Smile",
    EXTERMINATE: "Exterminate human race",
    KICK: "Kick",
    WRITE: "Write"
}

const ACTIONCOLORS = {
    PURPLE: "purple",
    CORAL: "coral",
    ORANGE: "orange",
    GREEN: "green",
    BLUE: "blue",
    RED: "red",
    SLATEBLUE: "slateBlue"
}

let activitiesToPerform = [];

let actionBlockParameters = {}

Object.keys(ACTIONS).map((actionsKey, index) => {
    let actionColorKeys = Object.keys(ACTIONCOLORS);
    actionBlockParameters[actionsKey] = {
        text: ACTIONS[actionsKey],
        color: ACTIONCOLORS[actionColorKeys[index]]
    }
}) // actionBlockParameters = { TALK = {text: "Talk", color: "purple"}, [...] }

const allActivitesPanel = document.querySelector(".right-panel");
const myActivitesPanel = document.querySelector(".left-panel");

const createActionDiv = (text, color) => {
    let actionDiv = document.createElement('div');
    actionDiv.classList.add('panel-item');
    actionDiv.classList.add(color);
    let actionDivText = document.createElement('span');
    actionDivText.textContent = text;
    actionDiv.appendChild(actionDivText);
    return actionDiv
}

const removeActivity = (event) => {
    let node = event.target;
    let parent = node.parentNode;
    let indexToRemove = Array.from(parent.children).indexOf(node);
    activitiesToPerform.splice(indexToRemove, 1);
    parent.removeChild(node);
}

const addActivity = (activity) => {
    let actionDiv = createActionDiv(actionBlockParameters[activity].text, actionBlockParameters[activity].color);
    actionDiv.onclick = removeActivity;
    activitiesToPerform.push(activity);
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
