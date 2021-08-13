var ACTIONS = {
    SPEAK: "Talk",
    WAVE: "Wave",
    HOME: "Return to home position",
    EMOTION: "Display an Emotion",
    VICTORY: "Perform a victory pose",
    FONZIE: "Fonzie",
    SLEEP: "Sleep"
}

var OPTIONS = {
    SPEAK: [
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
            default_value: 1
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
    HOME: [
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
    VICTORY: [
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
                "Smile",
                "Sad",
                "Angry",
                "Surprised",
                "Suspicious",
                "Evil"
            ],
            default_value: 0
        }
    ]
}

var ACTIONCOLORS = ["233d4d","fe7f2d","fcca46","a1c181","619b8a"]