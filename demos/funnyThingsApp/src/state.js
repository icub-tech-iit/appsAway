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
    if (activities.length < 1) return false; // There should be at least one activity
    for (let activity of activities) {
        if (!ACTIONS.hasOwnProperty(activity.activity)) return false;
        let possibleOptionValues = OPTIONS[activity.activity];
        if (Array.isArray(possibleOptionValues)) {
            for (let optionTemplate of possibleOptionValues) {
                if (!Array.isArray(activity.options)) return false;
                let importedOption = activity.options.filter(option => option.label == optionTemplate.label)
                if (importedOption.length !== 1) return false; // There should be exactly one option with the same label as the template
                importedOption = importedOption[0]
                let optionType = optionTemplate.type;
                switch (optionType) {
                    case "string":
                        if (typeof importedOption.value !== "string") return false;
                        break;
                    case "float":
                        let floatRegex = new RegExp("^-?\\d*(\\.\\d+)?$")
                        if (!floatRegex.test(importedOption.value)) return false;
                        break;
                    case "select":
                    case "dropdown":
                        if (!optionTemplate.options.some(optionValue => optionValue == importedOption.value)) return false;
                        break;
                    default:
                        return false;
                }
            }
        } else if(activity.hasOwnProperty("options")) {
            return false;
        }
    }
    return true;
}