# ################################################################################################
# SCRIPT NAME: appsAway_setEnvironment.sh
#
# DESCRIPTION: setup the customized enviroment
#              enviroment variables always starts with "APPSAWAY_"
#              and ends with a sort of variable descriptions where
#                _NAME is a string
#                _PATH is a path
#                _ADDR is an IP addr or hostname
#                _FILE is a file name
#                _LIST a space-separated list (this can ne added to any of above, es. _FILE_LIST)
#
# AUTHOR : Matteo Brunettini <matteo.brunettini@iit.it>
#
# LATEST MODIFICATION DATE (YYYY-MM-DD): 2019-12-06s
#
#
# ###############################################################################################

export APPSAWAY_APP_NAME=""
export APPSAWAY_USER_NAME=""
export APPSAWAY_USER_PASSWORD=""
export APPSAWAY_APP_PATH="/home/${APPSAWAY_USER_NAME}/appsAway/${APPSAWAY_APP_NAME}"
export APPSAWAY_ICUBHEADNODE_ADDR=""
export APPSAWAY_GUINODE_ADDR=""
export APPSAWAY_CONSOLENODE_ADDR=""
export APPSAWAY_DEPLOY_YAML_FILE_LIST=""
export APPSAWAY_GUI_YAML_FILE_LIST="compose4GuiApp.yml"
export APPSAWAY_HEAD_YAML_FILE_LIST="compose4Head.yml"
export APPSAWAY_STACK_NAME="APPSAWAY_stack"
export APPSAWAY_NODES_ADDR_LIST="$APPSAWAY_GUINODE_ADDR $APPSAWAY_ICUBHEADNODE_ADDR $APPSAWAY_CONSOLENODE_ADDR"
