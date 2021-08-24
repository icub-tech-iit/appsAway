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
                }
                switch (option.type) {
                    case 'string':
                    case 'float':
                        optionValue.value = option.default_value;
                        break;
                    default:
                        optionValue.value = option.options[option.default_value];
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

var checkActivites = (activities) => {
    if (!Array.isArray(activities)) return false;
    if (activities.length < 1) return false;
    for (let activity of activities) {
        let options = activity.options
        if (!Array.isArray(options) && activity.activity !== 'FONZIE') return false;
        switch (activity.activity) {
            case 'SPEAK':
                options.forEach((option)=>{
                    switch (option.label) {
                        case 'Text:':
                            if (typeof(option.value) !== "string") return false;
                            break;
                        case 'Wait until finish:':
                            if (!OPTIONS.SPEAK[1].options.includes(option.value)) return false;
                            break;
                        default:
                            return false;
                    }
                })
                break;
            case 'WAVE':
            case 'HOME':
            case 'VICTORY':
                if (options.length !== 1) return false;
                if (options[0].label !== 'Arm(s):') return false;
                if (!OPTIONS.WAVE[0].options.includes(options[0].value)) return false;
                break;
            case 'EMOTION':
                if (options.length !== 1) return false;
                if (options[0].label !== 'Emotion:') return false;
                if (!OPTIONS.EMOTION[0].options.includes(options[0].value)) return false;
                break;
            case 'FONZIE':
                break;
            case 'SLEEP':
                if (options.length !== 1) return false;
                if (options[0].label !== 'Time:') return false;
                if (!/^[0-9]+(\.)?[0-9]*$/.test(options[0].value)) {console.log(options[0].value); return false};
                //if (typeof(options[0].value !== 'number')) return false;
                break;
            default:
                return false;
        }
    }
    return true;
}