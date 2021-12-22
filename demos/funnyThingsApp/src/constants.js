var ACTIONS = {
    SPEAK: "Talk",
    WAVE: "Wave",
    HOME: "Return to Home Position",
    EMOTION: "Display an Emotion",
    VICTORY: "Perform a Victory Pose",
    FONZIE: "Fonzie",
    MUSCLES: "Show Muscles",
    GESTURE: "Show Gesture",
    QUESTION: "Raise Hand",
    GREET: "Greet with Thumb",
    SLEEP: "Sleep",
    POINTEYE: "Point eyes",
    POINTEARS: "Point ears",
    POINTARM: "Point arms",
    BALANCE: "Perform a Balancing Motion",
    GAZETYPE: "Set Gaze Behaviour",
    GAZELOOK: "Look at Cartesian Points",
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
                "Yes",
                "No"
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
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
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
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
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
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    MUSCLES: [
        {
            type: "select",
            label: "Arm(s):",
            options: [
                "Left",
                "Right",
                "Both"
            ],
            default_value: 1
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    GESTURE: [
        {
            type: "select",
            label: "Arm(s):",
            options: [
                "Left",
                "Right",
                "Both"
            ],
            default_value: 1
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    QUESTION: [
        {
            type: "select",
            label: "Arm(s):",
            options: [
                "Left",
                "Right",
                "Both"
            ],
            default_value: 1
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    GREET: [
        {
            type: "select",
            label: "Arm(s):",
            options: [
                "Left",
                "Right",
                "Both"
            ],
            default_value: 1
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    POINTEYE: [
        {
            type: "select",
            label: "Arm:",
            options: [
                "Left",
                "Right"
            ],
            default_value: 1
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    POINTARM: [
        {
            type: "select",
            label: "Arm:",
            options: [
                "Left",
                "Right"
            ],
            default_value: 1
        },
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    POINTEARS: [
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    BALANCE: [
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    SLEEP: [
        {
            type: "float",
            label: "Time:",
            default_value: 0.0
        }
    ],
    FONZIE: [
        {
            type: "select",
            label: "Wait until finished:",
            options: [
                "Yes",
                "No"
            ],
            default_value: 0
        }
    ],
    EMOTION: [
        {
            type: "dropdown",
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
    ],
    GAZETYPE: [
        {
            type: "select",
            label: "Type:",
            options: [
                "Idle",
                "Look-Around"
            ],
            default_value: 0
        }
    ],
    GAZELOOK: [
        {
            type: "float",
            label: "X:",
            default_value: "15.0"
        },
        {
            type: "float",
            label: "Y:",
            default_value: "0.0"
        },
        {
            type: "float",
            label: "Z:",
            default_value: "5.0"
        },
    ],

}

//var ACTIONCOLORS = ["233d4d","fe7f2d","fcca46","a1c181","619b8a"]
var ACTIONCOLORS = ["f94144","f3722c","f8961e","f9c74f","90be6d","43aa8b","577590"]