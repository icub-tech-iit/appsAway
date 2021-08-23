var activitiesToPerform = []

var run = false;

var addActivity = (activity) => {
    if (ACTIONS.hasOwnProperty(activity)) {
        let newActivity = {
            activity
        }
        if (OPTIONS.hasOwnProperty(activity)) {
            let options = []
            for (let option of OPTIONS[activity]) {
                let optionValue = {
                    label: option.label,
                    value: option.type == "string" ? option.default_value : option.options[option.default_value]
                }
                options.push(optionValue)
            }
            newActivity.options = options
        }
        activitiesToPerform.push(newActivity)
    }
}

var removeActivity = (indexToRemove) => {
    if (indexToRemove < activitiesToPerform.length) {
        activitiesToPerform.splice(indexToRemove, 1);
    }
} 

var repositionActivity = (indexToChange, newPosition) => {
    activitiesToPerform.splice(newPosition, 0, activitiesToPerform.splice(indexToChange, 1)[0])
}

var clearActivities = () => {
    activitiesToPerform = []
}

var changeActivityValue = (activityIndex, optionIndex, value) => {
    activitiesToPerform[activityIndex].options[optionIndex].value = value
}