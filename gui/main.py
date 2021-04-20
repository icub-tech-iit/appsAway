from fbs_runtime.application_context.PyQt5 import ApplicationContext
from PyQt5.QtCore import QDateTime, Qt, QTimer, QElapsedTimer
from PyQt5.QtWidgets import (QApplication, QCheckBox, QComboBox, QDateTimeEdit,
        QDial, QDialog, QGridLayout, QGroupBox, QHBoxLayout, QLabel, QLineEdit,
        QProgressBar, QPushButton, QRadioButton, QScrollBar, QSizePolicy,
        QSlider, QSpinBox, QStyleFactory, QTableWidget, QTabWidget, QTextEdit,
        QVBoxLayout, QWidget, QLineEdit, QFileDialog )

from PyQt5.QtGui import QIcon, QPixmap, QImage
from PyQt5.QtCore import pyqtSlot, QSize, QUrl, QRect
from itertools import chain
from PyQt5.QtMultimedia import QMediaContent, QMediaPlayer

import sys
import time
import subprocess
import os 

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from enum import Enum


global PAUSED
PAUSED = True



class ButtonType(Enum):
    FILE_INPUT = ("fileInput")
    TOGGLE_BUTTON = ("toggleButton")
    DROPDOWN_LIST = ("dropdownList")
    AUDIO_INPUT = ("audioInput")
    RADIO_BUTTON = ("radioButton")
    TEXT_EDIT_BUTTON = ("textEditButton")
    TEXT_EDIT_BOX = ("textEditBox")
    PUSH_BUTTON = ("pushButton")
    START_BUTTON = ("startButton")

    @staticmethod
    def in_line(line: str) -> bool:
        for by in ButtonType:
            if by.value in line:
                return True

        return False

class OptionButton():
    def __init__(self, varType, button, varName, inputBox, outputs, label):
        self.varType = varType # radioButton, etc
        self.button = button # the type of Qt button 
        self.varName = varName # the name of the corresponding environment variable
        self.label = label # "" or a title

        # USED ONLY IF NOT RADIOBUTTONS OR RADIOBUTTONS WITH TEXTBOX
        # boolean to indicate if it is required to fill this button
        #self.is_required = is_required 
        self.inputBox = inputBox # the Qt object for the input box

        # USED ONLY IF CHECKBOX[2], RADIOBUTTON[1], PUSHBUTTON[file_path/settings], OR DROPDOWN LISTS[multiple]
        # what checked/unchecked means, e.g. [true, false] for checkbox, [value] for radiobutton
        self.outputs = outputs    

        # Buttons it depends on (is only enabled if other button are selected) - structure: [[GOOGLE_check, on, off], [...], ... ]
        # [var_name of the external button, status of the external button, effect on the current button]
        self.dependencies = ""
        self.options = []


    @staticmethod
    def createElement(line: str, widget_gallery) -> 'AbstractClass':
        els = line.split('"')
        els = [el.strip() for el in els]

        button_type, button_label, _discard, button_text, other = els

        try:
            button_type = ButtonType(button_type)
        except:
            button_type = None

        if button_label != "":
          label = QLabel(button_label)
        else:
          label = None

        var_name, val_value, initial_setting, ticked_state  = other.split(' ')

        if val_value == "None":
          val_value = None
        elif val_value.find('/'):
          val_value = val_value.split('/')

        if button_type == ButtonType.RADIO_BUTTON:
            inputButton = None
            button = QRadioButton(button_text)
            if initial_setting == "off":
              button.setEnabled(False)

        elif button_type == ButtonType.TEXT_EDIT_BUTTON:
            inputButton = QLineEdit(widget_gallery)
            inputButton.setPlaceholderText(var_name)
            button = QRadioButton(button_text)
            if initial_setting == "off":
              button.setEnabled(False)
              inputButton.setEnabled(False)

        elif button_type == ButtonType.TEXT_EDIT_BOX:
            inputButton = QLineEdit(widget_gallery)
            inputButton.setPlaceholderText(var_name)
            button = None
            if initial_setting == "off":
              inputButton.setEnabled(False)

        elif button_type == ButtonType.FILE_INPUT:
            inputButton = QLineEdit(widget_gallery)
            inputButton.setPlaceholderText(var_name)
            button = QPushButton(button_text)
            if initial_setting == "off":
              inputButton.setEnabled(False)
              button.setEnabled(False)

        elif button_type == ButtonType.TOGGLE_BUTTON:
            inputButton = None
            button = QCheckBox(button_text)
            if initial_setting == "off":
              button.setEnabled(False)
            if ticked_state == "ticked":
              button.setChecked(True)

        elif button_type == ButtonType.DROPDOWN_LIST:
            inputButton = None
            button = QComboBox(widget_gallery)
            for _value in val_value:
              button.addItem(_value)
            button.move(50, 250)
            if initial_setting == "off":
              button.setEnabled(False)

        elif button_type == ButtonType.PUSH_BUTTON:
            inputButton = None
            pixmap = QPixmap('images/audioicon.png')
            button = QPushButton(button_text)
            button.setGeometry(200, 150, 50, 50)
            button.setIcon(QIcon(pixmap))
            button.setIconSize(QSize(50, 50))

        elif button_type == ButtonType.AUDIO_INPUT:
            inputButton = None
            pixmap = QPixmap('images/audioicon.png')
            button = QPushButton(button_text)
            button.setGeometry(200, 150, 50, 50)
            button.setIcon(QIcon(pixmap))
            button.setIconSize(QSize(50, 50))

        return OptionButton(button_type.value, button, var_name, inputButton, val_value, label)

class MyHandler(FileSystemEventHandler):
    def __init__(self, progressBar, pushStopButton):
        self.progressBar = progressBar
        self.pushStopButton = pushStopButton
    def on_modified(self, event):
        global PAUSED
        if PAUSED:
          return
        if os.path.isfile("PIPE"):
          pipe_file = open("PIPE", "r")
          line = pipe_file.readline()
          if line == '':
            return
          curVal = int(line)
          maxVal = self.progressBar.maximum()
          self.progressBar.setValue(curVal + (maxVal - curVal) / 100)
          if curVal == 100:
            self.progressBar.setFormat("Application is being deployed!")
            self.pushStopButton.setEnabled(True)
            PAUSED = True
          pipe_file.close()


########################################################## right options ######################################################################
###############################################################################################################################################
# Button type     # button title                    # button text       # variable name     # value       # initial status  # ticked          #
# radioButton     # ""                              # "robot cameras"   # ROBOT_CAMERAS     # yes         # on              # None            #
# textEditButton  # ""                              # "text input"      # INPUT_BUTTON      # None        # on              # None            #
# textEditBox     # "Insert the name of your agent" # "text input"      # INPUT_BOX         # None        # on              # None            #
# fileInput       # ""                              # "Google file"     # FILE_INPUT        # None        # on              # None            #
# toggleButton    # ""                              # "Google Input"    # GOOGLE_INPUT      # true/false  # on              # ticked/unticked #
# dropdownList    # "Language of the dialogflow:"   # "Language sel"    # LANG_INPUT        # en-US/it-IT # off             # None            #
# pushButtom      # ""                              # "Try your voice!" # AUDIO_INPUT       # None        # on              # None            #
###############################################################################################################################################

############################################################# button hierarchy ################################################################
###############################################################################################################################################
# NOTES:                                                                                                                                      #
#     There should ALWAYS be a START_BUTTON dependency, as it specifies when the startApplication button becomes available                    #
#                                                                                                                                             #
#     The logic of the dependency goes as follows:                                                                                            #
#         logic is defined by C++ symbols:                                                                                                    #
#           AND - &&                                                                                                                          #
#           OR - ||                                                                                                                           #
#         Predicates are specified between {}:                                                                                                #
#           {"name of button it depends on" "type of dependency (selected/unselected)" "effect of trigger (enable/disable)"}                  #
#         Operations are split by brackets ():                                                                                                #
#           e.g.: ( ( {A} && {B} ) || {C} )                                                                                                   #
###############################################################################################################################################
################################################################# Examples ####################################################################
###############################################################################################################################################
# TYPE (Dependency    # variable name         # logic of dependency                                                                           #
# Dependency -        # START_BUTTON -        # ( {FILE_INPUT selected enable} && {INPUT_BOX selected enable} )                               #
# Dependency -        # VOICE_NAME_INPUT -    # ( {GOOGLE_SYNTHESIS_INPUT selected enable} )                                                  #
###############################################################################################################################################

############################################################# Button Options ##################################################################
###############################################################################################################################################
# NOTES:                                                                                                                                      #
#   The logic of the options goes as follows:                                                                                                 #
#     first you specify the name of the button whose options depend on another button (button_name)                                           #
#     Then you specify the name of the button that will trigger changes on this button (parent_button_name)                                   #
#     Then you specify the list of parent options split by /: [en-GB/it-IT]                                                                   #
#     Finally you specify the options that become available when each of this options is chosen, in a list of list:                           #
#       [[en-GB-Wavenet-A/en-GB-Wavenet-B/en-GB-Wavenet-C/en-GB-Wavenet-D],[it-IT-Wavenet-A/it-IT-Wavenet-B/it-IT-Wavenet-C/it-IT-Wavenet-D]] #
###############################################################################################################################################
############################################################### Examples ######################################################################
###############################################################################################################################################
# OptionList   # button_name      # parent_button_name     # list of parent options        # list of child options                            #
# OptionList - VOICE_NAME_INPUT - LANGUAGE_SYNTHESIS_INPUT [en-US/en-GB/fr-FR/pt-PT/it-IT] [[...],[...]]                                      #
###############################################################################################################################################

class WidgetGallery(QDialog):
    def __init__(self, parent=None):
        super(WidgetGallery, self).__init__(parent)
        self.label = QLabel(self)

        self.title = "" #"Grasp the Ball Application"
        self.image = "" #'src/main/images/redball.jpg'

        self.rc = None #inits the subprocess
        self.ansible = subprocess.Popen(['true'])

        self.button_list = []

        self.gui_dir = os.getcwd()

        # read from .ini file here
        self.button_name_list = []
        global find_startAskInput #to have access from stop Application 
        find_startAskInput = False
        conf_file = open(os.path.join(self.gui_dir, "gui_conf.ini"), "r")

# TODO: put sanity checks on the inputs from the .ini file, just in case

        self.pushUpdateButton = QPushButton("Everything is Up to Date!")
        self.pushStartButton = QPushButton("Start the Application")
        self.startButtonEntry = OptionButton("startButton", self.pushStartButton, "START_BUTTON", None, None, "")
        self.button_list.append(self.startButtonEntry)
        self.pushStopButton = QPushButton("Stop the Application")

        for line in conf_file:
          line = line.replace('\n', '').replace('\r','').strip()
          if line.find("title") != -1:
            self.title = line.split('"')[1]
          if line.find("ImageName") != -1:
            self.image = os.path.join(self.gui_dir, line.split('"')[1])

          if ButtonType.in_line(line):
            self.button_list.append(OptionButton.createElement(line, self))

          # this will add the dependencies to the respective buttons in the class
          # dependencies should be written in the following format: "Dependency - INPUT_FILE - GOOGLE_INPUT on on - ..."
          if line.find("Dependency") != -1:
            dependency_list = line.replace('\n', '').split(' - ')
            for button in self.button_list:
              if button.varName == dependency_list[1]:
                button.dependencies = dependency_list[2]

          if line.find("OptionList") != -1:
            option_list = line.replace('\n', '').split(' - ')
            for button in self.button_list:
              if button.varName == option_list[1]:
                temp_opt = option_list[2].split(' ')
                if temp_opt[1].find('[') != -1:
                  temp_opt[1]=temp_opt[1].replace('[','').replace(']','').split('/')
                if temp_opt[2].find('[') != -1:
                  temp_opt[2] = temp_opt[2].replace('[','').replace(']','').split(',')
                button.options = button.options + [[temp_opt[0], temp_opt[1], temp_opt[2]]]



        os.chdir(os.path.join(os.environ.get('HOME'),"teamcode","appsAway","scripts"))
        if os.path.isfile("PIPE"):
          os.remove("PIPE")

        self.timer = QTimer(self)

        self.createTopGroupBox()
        self.createBottomLeftGroupBox()
        self.createBottomRightGroupBox()

        self.timer.timeout.connect(self.checkForUpdates)
        self.timer.start(300000)  


        self.createProgressBar()
        self.event_handler = MyHandler(self.progressBar, self.pushStopButton)
        self.observer = Observer()
        self.observer.schedule(self.event_handler, path=os.getcwd(), recursive=False)
        self.observer.start()
        

        mainLayout = QGridLayout()
        mainLayout.addWidget(self.topGroupBox, 0, 0, 1, 2)
        mainLayout.addWidget(self.bottomLeftGroupBox, 1, 0)
        mainLayout.addWidget(self.bottomRightGroupBox, 1, 1)
        mainLayout.addWidget(self.progressBar, 2, 0, 1, 2)
        self.setLayout(mainLayout)
        self.setWindowTitle("iCub-Tech Application Deployment")
        self.changeStyle('Fusion')
        self.bottomLeftGroupBox.setDisabled 

        
    def changeStyle(self, styleName):
        QApplication.setStyle(QStyleFactory.create(styleName))
        QApplication.setPalette(QApplication.style().standardPalette())

    def createTopGroupBox(self):
        self.topGroupBox = QGroupBox(self.title)

        self.topGroupBox.setAlignment(Qt.AlignHCenter) 

        layout = QVBoxLayout()
        
        self.pushUpdateButton.setDefault(True)    

        out = subprocess.Popen(['./appsAway_checkUpdates.sh'], 
           stdout=subprocess.PIPE, 
           stderr=subprocess.STDOUT)
        
        stdout,stderr = out.communicate()

        if b"true" in stdout:
          self.pushUpdateButton.setEnabled(True)
          self.pushUpdateButton.setText("Update Available")
        elif b"false" in stdout:
          self.pushUpdateButton.setEnabled(False)
          self.pushUpdateButton.setText("Everything is Up to Date!")

        layout.addWidget(self.pushUpdateButton)


        pixmap = QPixmap(self.image)
        if pixmap.height() > 250:
          pixmap = pixmap.scaledToHeight(250, Qt.SmoothTransformation)

        self.label.setPixmap(pixmap)
        #self.resize(pixmap.width(),pixmap.height())
        #self.show()
        layout.addWidget(self.label)
        layout.addStretch(1)
        layout.setAlignment(Qt.AlignCenter)
        self.topGroupBox.setLayout(layout)

        self.pushUpdateButton.clicked.connect(self.startUpdate)
    
########################################################## right options ###########################################################################
####################################################################################################################################################
# Button type     # button text       # variable name     # value                                                           # status  # required   #
# radioButton     # "robot cameras"   # ROBOT_CAMERAS     # yes                                                             # on      # False      #
# textEditButton  # "text input"      # INPUT_BUTTON      # None                                                            # on      # False      #
# textEditBox     # "text input"      # INPUT_BOX         # None                                                            # on      # False      #
# fileInput       # "Google file"     # FILE_INPUT        # None                                                            # on      # False      #
# toggleButton    # "Google Input"    # GOOGLE_INPUT      # true/false                                                      # on      # False      #
# dropdownList    # "Language sel"    # LANG_INPUT        # en-US/it-IT                                                     # off     # False      #
# pushButtom      # "Try your voice!" # AUDIO_INPUT       # /home/laura/teamcode/appsAway/demos/synthesis/audioicon.png     # on      # False      #
####################################################################################################################################################

    def createBottomRightGroupBox(self):
        self.bottomRightGroupBox = QGroupBox("Application Options")

        self.bottomRightGroupBox.setAlignment(Qt.AlignHCenter)

        found_radio = False

        layout = QVBoxLayout()
        for buttonOption in self.button_list:

          if buttonOption.varType == "startButton":
            continue

          if buttonOption.label != None:
            layout.addWidget(buttonOption.label)
          if buttonOption.button != None:
            layout.addWidget(buttonOption.button)
          if buttonOption.inputBox != None:
            layout.addWidget(buttonOption.inputBox)

          # if this is the first radio button, we set it to true, and only this one
          if (buttonOption.varType == 'radioButton' or buttonOption.varType == 'textEditButton'):
            #layout.addWidget(buttonOption.button)
            if not found_radio:
              buttonOption.button.setChecked(True)
            buttonOption.button.clicked.connect(self.on_click(buttonOption))
            found_radio = True 
            self.disableAllOthers(buttonOption)

          # This adds the radiobutton and the corresponding text box
          if buttonOption.varType == 'textEditButton':
            #layout.addWidget(buttonOption.button)
            #layout.addWidget(buttonOption.inputBox)
            buttonOption.button.clicked.connect(self.on_click(buttonOption))
            buttonOption.inputBox.textChanged.connect(self.checkToggleState(buttonOption))

          # This adds the radiobutton and the corresponding text box
          if buttonOption.varType == 'textEditBox':
            #layout.addWidget(buttonOption.button)
            #layout.addWidget(buttonOption.inputBox)
            buttonOption.inputBox.textChanged.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'fileInput':
            #layout.addWidget(buttonOption.button)
            #layout.addWidget(buttonOption.inputBox)
            buttonOption.button.clicked.connect(self.openFile(buttonOption))
            buttonOption.inputBox.textChanged.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'toggleButton':
            #layout.addWidget(buttonOption.button)
            buttonOption.button.stateChanged.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'dropdownList':
            #layout.addWidget(buttonOption.button)
            buttonOption.button.activated.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'audioInput':
            #layout.addWidget(buttonOption.button)
            buttonOption.button.clicked.connect(self.playAudio())

        # now we check the dependencies for all buttons, and enable/disable buttons accordingly
        for buttonOption in self.button_list:
          self.checkDependencies(buttonOption)

        layout.addStretch(1)
        self.bottomRightGroupBox.setLayout(layout)   

    def recursion(self, statement):
      #statement = statement.replace(' ', '')
      for i in range(len(statement)):
        if i >= len(statement):
          break;
        if statement[i] == '(':
          statement = statement[:i] + self.recursion(statement[i+1:])
        if statement[i] == ')':
          statement = self.solve(statement[:i]) + statement[i+1:]
          return statement
      return statement    


    def solve(self, statement):
      expression_tmp = statement.split('{')
      expression = []
      for elem in expression_tmp:
        expression = expression + elem.split('}')
      has_operator = False
      for i in range(len(expression)):
        if expression[i] == '' or expression[i] == ' ':
          continue
        if expression[i].find('&&') == -1 and expression[i].find('||') == -1: # if it is not an operator
          if has_operator:
            if expression[i-1].find('&&') != -1: # if it was an and
              if expression[i] == 'True':
                intermediate_result = intermediate_result and True
              elif expression[i] == 'False':
                intermediate_result = intermediate_result and False
              else:
                intermediate_result = intermediate_result and self.evaluate_button(expression[i]) 
            else:
              if expression[i] == 'True':
                intermediate_result = intermediate_result or True
              elif expression[i] == 'False':
                intermediate_result = intermediate_result or False
              else:
                intermediate_result = intermediate_result or self.evaluate_button(expression[i]) 
            has_operator = False
          else:
            if expression[i] == 'True':
              intermediate_result = True
            elif expression[i] == 'False':
              intermediate_result = False
            else:
              intermediate_result = self.evaluate_button(expression[i]) 
        elif expression[i].find('&&') != -1 or expression[i].find('||') != -1: # if it IS an operator
          has_operator = True
        else:
          return False
      if intermediate_result:
        return "{True}"
      else:
        return "{False}"


    def evaluate_button(self, statement): # statement should be in the form of "BUTTON_NAME status effect"
      statement_list = statement.split(' ')
      for button in self.button_list:
        if button.varName == statement_list[0]:
          if (((button.varType == "radioButton" or button.varType == "toggleButton") and 
            ((statement_list[1] == "selected" and button.button.isChecked()) or 
            (statement_list[1] == "unselected" and not button.button.isChecked()))) or 
            ((button.varType == "textEditBox" or (button.varType == "textEditButton" and button.button.isChecked())) and button.inputBox.text() != "") or
            (button.varType == "fileInput" and button.inputBox.text() != "") or 
            (button.varType == "dropdownList" and (statement_list[1].find(button.button.currentText()) != -1))):
            if statement_list[2] == 'enable':
              return True
            else: 
              return False
          else:
            if statement_list[2] == 'enable':
              return False
            else: 
              return True
          

    def checkDependencies(self, buttonOption):
      result = self.recursion(buttonOption.dependencies)
      #print("result: ", result)
      #print("button: ", buttonOption.varType)
      if result == "{True}":
        if buttonOption.button != None:
          buttonOption.button.setEnabled(True)
        if buttonOption.inputBox != None:
          buttonOption.inputBox.setEnabled(True)
      elif result == "{False}":
        if buttonOption.button != None:
          buttonOption.button.setEnabled(False)
        if buttonOption.inputBox != None:
          buttonOption.inputBox.setEnabled(False)

      # now we handle the options
      if buttonOption.varType == 'dropdownList': # we change the options of the button dropwdown
        for option in buttonOption.options:
          for button in self.button_list:
            if button != buttonOption:
              if button.varName == option[0]:
                opt_temp = option[2][option[1].index(button.button.currentText())] # we want the set of options corresponding to the correct trigger
                opt_list = opt_temp.split('/')
                prev_opt = []
                for i in range(buttonOption.button.count()):
                  prev_opt = prev_opt + [buttonOption.button.itemText(i)]
                if opt_list != prev_opt:
                  buttonOption.button.clear()
                  for new_item in opt_list:
                    buttonOption.button.addItem(new_item)
 
    
    @pyqtSlot()
    def checkToggleState(self,buttonOption):
      def checkButtonState():
        for button in self.button_list: # check the status of all buttons
          self.checkDependencies(button)
      return checkButtonState

    @pyqtSlot()
    def playAudio(self):
      def play():
        sel_voice=[el.button.currentText() for el in list(filter(lambda x: x.varName == 'VOICE_NAME_INPUT', self.button_list)) ] #to avoid another for loop on all the buttons, we do a filter 
        sel_lang=[el.button.currentText() for el in list(filter(lambda x: x.varName == 'LANGUAGE_SYNTHESIS_INPUT', self.button_list)) ] #here we have the selected voice
        
        rc = subprocess.call(["play", os.path.join('..','gui','target','appGUI','Archive','language '+ sel_lang[0] + '_' + sel_voice[0] + '.mp3')])

      return play


    @pyqtSlot()
    def openFile(self, buttonOption):
      def takeFile():
        filename, _ = QFileDialog.getOpenFileName(self, "Choose file", "/home", "File extension Json (*.json)")
        buttonOption.inputBox.setText(filename)
      return takeFile


    @pyqtSlot()
    def on_click(self, buttonOption):
      def setEnable():
        if buttonOption.inputBox != None:
          buttonOption.inputBox.setEnabled(True)
        self.disableAllOthers(buttonOption)
        for button in self.button_list: # check the status of all buttons
          self.checkDependencies(button)
      return setEnable

    def disableAllOthers(self, currentOption):
      for buttonOption in self.button_list:
        if buttonOption.varType == 'textEditButton':
          if buttonOption != currentOption:
            buttonOption.inputBox.setEnabled(False)

    def createBottomLeftGroupBox(self):
        self.bottomLeftGroupBox = QGroupBox("Application")

        self.bottomLeftGroupBox.setAlignment(Qt.AlignHCenter)
        
        self.pushStartButton.setDefault(True)
        self.pushStartButton.setEnabled(True)
    
        self.pushStopButton.setDefault(True)
        self.pushStopButton.setEnabled(False)

        layout = QVBoxLayout()
        layout.addWidget(self.pushStartButton)
        layout.addWidget(self.pushStopButton)

        self.pushStartButton.clicked.connect(self.startProgressBar)
        self.pushStopButton.clicked.connect(self.stopApplication)

        self.bottomLeftGroupBox.setLayout(layout)    

    def createProgressBar(self):
        self.progressBar = QProgressBar()
        self.progressBar.setRange(0, 100)
        self.progressBar.setValue(0)
       

    def startProgressBar(self):
        global PAUSED
        self.pushStartButton.setEnabled(False)
        self.pushStopButton.setEnabled(False)

        for buttonOption in self.button_list:
          if buttonOption.button != None:
            buttonOption.button.setEnabled(False)
          if buttonOption.inputBox != None:
            buttonOption.inputBox.setEnabled(False)

        PAUSED = False
        
        elapsedTime = QElapsedTimer()
        elapsedTime.start()

        self.startApplication()

            
    def stopProgressBar(self):
        self.pushStopButton.setEnabled(True)

    def checkForUpdates(self):
        if self.ansible.poll() == None:
          return
        self.timer.start(300000)
        out = subprocess.Popen(['./appsAway_checkUpdates.sh'], 
           stdout=subprocess.PIPE, 
           stderr=subprocess.STDOUT)
        
        stdout,stderr = out.communicate()

        if b"true" in stdout:
          self.pushUpdateButton.setEnabled(True)
          self.pushUpdateButton.setText("Update Available")
        elif b"false" in stdout:
          self.pushUpdateButton.setEnabled(False)
          self.pushUpdateButton.setText("Everything is Up to Date!")

    def startUpdate(self):
        # first we pause the timer
        self.timer.start(1000)
        self.pushUpdateButton.setEnabled(False)
        self.pushUpdateButton.setText("Installing....")
        # then we change working directory
        #os.chdir("ansible_setup") 
        os.chdir(os.path.join(os.environ.get('HOME'),"teamcode","appsAway","scripts","ansible_setup"))
        rc = subprocess.call("./setup_hosts_ini.sh")
        self.ansible = subprocess.Popen(['make', 'prepare'])
        #os.chdir("..") 
        os.chdir(os.path.join(os.environ.get('HOME'),"teamcode","appsAway","scripts"))

    def startApplication(self):
        print("starting application")
        global googleSynthesis_found
        googleSynthesis_found = False
        #self.custom_option = "";
        for buttonOption in self.button_list:

            # I need to do this 2-step check since "button" might not exist and crash in "button.isEnabled"
            proceed_flag = False
            if buttonOption.button != None:
              if buttonOption.button.isEnabled:
                proceed_flag = True
              else: # if the button is disabled we should ignore its value
                os.environ[buttonOption.varName] = ""

            if (proceed_flag or (buttonOption.button == None and buttonOption.inputBox.isEnabled)):
              if buttonOption.varType == 'fileInput':
                  file_input_path, file_input = os.path.split(buttonOption.inputBox.text())
                  os.environ[buttonOption.varName] = file_input
                  os.environ[buttonOption.varName + '_PATH'] = file_input_path
              elif buttonOption.varType == 'dropdownList':
                  os.environ[buttonOption.varName] = buttonOption.button.currentText()
              elif buttonOption.varType == 'toggleButton':
                  if buttonOption.button.isChecked():
                    os.environ[buttonOption.varName] = buttonOption.outputs[0]
                  else:
                    os.environ[buttonOption.varName] = buttonOption.outputs[1]
              elif buttonOption.varType == 'textEditBox': 
                  os.environ[buttonOption.varName] = buttonOption.inputBox.text()
              elif buttonOption.varType == 'textEditButton':
                  if buttonOption.button.isChecked():
                    os.environ[buttonOption.varName] = buttonOption.inputBox.text()
                  else:
                    os.environ[buttonOption.varName] = ""
            elif buttonOption.button == None and not buttonOption.inputBox.isEnabled:
              os.environ[buttonOption.varName] = ""
        self.setupEnvironment()
        rc = subprocess.Popen("./appsAway_startApp.sh", shell=True)
        #self.rc = subprocess.Popen("./appsAway_startApp.sh", stdout=subprocess.PIPE, shell=True)
    
    def stopApplication(self):
        global PAUSED
        print("stopping application\n\n")
        self.pushStartButton.setEnabled(True)
        self.pushStopButton.setEnabled(False)
        self.progressBar.setFormat("%p%")
        self.timer.stop()  
        self.progressBar.setValue(0)
        PAUSED = True


# TODO: should we actually clear all user options? if a user wants to quickly restart the demo, we should keep them

        for buttonOption in self.button_list:
          if buttonOption.button != None:
            buttonOption.button.setEnabled(True)
          if buttonOption.inputBox != None:
            buttonOption.inputBox.setEnabled(True)
          self.checkDependencies(buttonOption)      

        rc = subprocess.call("./appsAway_stopApp.sh")

    def setupEnvironment(self):
        os.chdir(os.path.join(os.environ.get('HOME'), "teamcode","appsAway","demos", os.environ.get('APPSAWAY_APP_NAME')))
        yml_files_default = ["main.yml", "composeGui.yml", "composeHead.yml"]
        yml_files = []

        for yml_file in yml_files_default:
          if os.path.isfile(yml_file):
            yml_files = yml_files + [yml_file]

        for yml_file in yml_files:
          main_file = open(yml_file, "r")
          main_list = main_file.read().split('\n')

          custom_option_found = False
          end_environ_set = False

          if os.environ.get('APPSAWAY_IMAGES') != '':
            list_images = os.environ.get('APPSAWAY_IMAGES').split(' ')
            list_versions = os.environ.get('APPSAWAY_VERSIONS').split(' ')
            list_tags = os.environ.get('APPSAWAY_TAGS').split(' ')

            for i in range(len(main_list)):
              if main_list[i].find("x-yarp-") != -1:
                if main_list[i+1].find("image") != -1:
                  image_line = main_list[i+1]
                  image_line = image_line.split(':')
                  for f in range(len(list_images)):
                    if image_line[1].strip() == list_images[f].strip(): # if the name is correct (the image name contains also the repository name - 'icubteamcode/superbuild')
                      image_line[2] = list_versions[f] + "_" + list_tags[f] # we update the version
                      break
                  main_list[i+1] = image_line[0] + ':' + image_line[1] + ':' + image_line[2]

          else:
            for i in range(len(main_list)):
              if main_list[i].find("x-yarp-base") != -1 or main_list[i].find("x-yarp-head") != -1 or main_list[i].find("x-yarp-gui") != -1:
                if main_list[i+1].find("image") != -1:
                  image_line = main_list[i+1]
                  image_line = image_line.split(':')
                  image_line[2] = os.environ.get('APPSAWAY_REPO_VERSION') + "_" + os.environ.get('APPSAWAY_REPO_TAG')
                  main_list[i+1] = image_line[0] + ':' + image_line[1] + ':' + image_line[2]

            if main_list[i].find("services") != -1:
                break
          main_file.close()
          main_file = open(yml_file, "w")
          for i in range(len(main_list)-1):
            main_file.write(main_list[i]+ '\n')
          main_file.write(main_list[-1])
          main_file.close()

        # env file is located in iCubApps folder, so we need APPSAWAY_APP_PATH
        os.chdir(os.environ.get('APPSAWAY_APP_PATH'))

        env_file = open(".env", "r")
        env_list = env_file.read().split('\n')
        env_file.close()

        # Checking if we already have all the environment variables in the .env; if yes we overwrite them, if not we add them 
        for button in self.button_list:
          not_found = True
          not_found_path = True
          for i in range(len(env_list)):
            if button.varType == 'fileInput':
              if env_list[i].find(button.varName + "_PATH=") != -1 and os.environ.get(button.varName + "_PATH") != None:
                env_list[i] = button.varName + "_PATH=" + os.environ.get(button.varName + "_PATH")
                not_found_path = False
            if env_list[i].find(button.varName + "=") != -1 and os.environ.get(button.varName) != None:
              env_list[i] = button.varName + "=" + os.environ.get(button.varName)
              not_found = False
          if not_found and os.environ.get(button.varName) != None:
            env_list.insert(len(env_list), button.varName + "=" + os.environ.get(button.varName))
          if not_found_path and os.environ.get(button.varName + "_PATH") != None:
            env_list.insert(len(env_list), button.varName + "_PATH=" + os.environ.get(button.varName + "_PATH"))


        env_file = open(".env", "w")
        for line in env_list:
          env_file.write(line + '\n')
        env_file.close()

        os.chdir(os.path.join(os.environ.get('HOME'), "teamcode","appsAway","scripts"))
          
        # now we copy all the files to their respective machines
        rc = subprocess.call("./appsAway_copyFiles.sh")

    # overload the closing function to close the watchdog
    def exec_(self):
        self.observer.stop()
        self.observer.join()
        self.installFinish.terminate()
        self.installFinish.join()
    

if __name__ == '__main__':
    appctxt = ApplicationContext()
    gallery = WidgetGallery()
    gallery.show()
    sys.exit(appctxt.app.exec_())
