var ACTIONS = {
    TALK: "Talk",
    WAVE: "Wave",
    GRASP: "Grasp an object",
    EMOTION: "Display an Emotion",
    EXTERMINATE: "Exterminate human race",
    KICK: "Kick",
    SLEEP: "Sleep"
}

var OPTIONS = {
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

var ACTIONCOLORS = ["ed8931","73556e","f07f56","d97373"]