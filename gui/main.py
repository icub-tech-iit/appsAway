from fbs_runtime.application_context.PyQt5 import ApplicationContext
from PyQt5.QtCore import QDateTime, Qt, QTimer, QElapsedTimer
from PyQt5.QtWidgets import (QApplication, QCheckBox, QComboBox, QDateTimeEdit,
        QDial, QDialog, QGridLayout, QGroupBox, QHBoxLayout, QLabel, QLineEdit,
        QProgressBar, QPushButton, QRadioButton, QScrollBar, QSizePolicy,
        QSlider, QSpinBox, QStyleFactory, QTableWidget, QTabWidget, QTextEdit,
        QVBoxLayout, QWidget, QLineEdit, QFileDialog )

from PyQt5.QtGui import QIcon, QPixmap
from PyQt5.QtCore import pyqtSlot, QSize, QUrl, QRect
from itertools import chain
from PyQt5.QtMultimedia import QMediaContent, QMediaPlayer

import sys
import time
import subprocess
import os 

import pygame
from pygame import mixer 

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

global PAUSED
PAUSED = True

class optionButton():
    def __init__(self, varType, button, varName, is_required, inputBox, outputs):
        self.varType = varType # radioButton, etc
        self.button = button # the type of Qt button 
        self.varName = varName # the name of the corresponding environment variable

        # USED ONLY IF NOT RADIOBUTTONS OR RADIOBUTTONS WITH TEXTBOX
        self.is_required = is_required # boolean to indicate if it is required to fill this button
        self.inputBox = inputBox # the Qt object for the input box

        # USED ONLY IF CHECKBOX[2], RADIOBUTTON[1], PUSHBUTTON[file_path/settings], OR DROPDOWN LISTS[multiple]
        self.outputs = outputs # what checked/unchecked means, e.g. [true, false] for checkbox, [value] for radiobutton   

        # Buttons it depends on (is only enabled if other button are selected) - structure: [[GOOGLE_check, on, off], [...], ... ]
        # [var_name of the external button, status of the external button, effect on the current button]
        self.dependencies = []


class MyHandler(FileSystemEventHandler):
    def __init__(self, progressBar):
        self.progressBar = progressBar
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
            PAUSED = True
          pipe_file.close()


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

######################################################## option dependencies #############################################################
##########################################################################################################################################
# Dependencies - parent variable name - child variable name [child status] effect[list of effects] - etc                                                #

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
        conf_file = open(self.gui_dir + "/gui_conf.ini", "r")

# TODO: put sanity checks on the inputs from the .ini file, just in case

        for line in conf_file:
          line.replace('\n', '').replace('\r','')
          if line.find("title") != -1:
            self.title = line.split('"')[1]
          if line.find("ImageName") != -1:
            self.image = self.gui_dir + "/" + line.split('"')[1]

          # radioButton option
          if line.find("radioButton") != -1:
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1] 
            var_name = line.split('" ')[1].split(' ')[0]
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','')
            var_value = line.split('" ')[1].split(' ')[1]
            radioButton = QRadioButton(button_text)
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              radioButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, radioButton, var_name, requisite, None, var_value)]

          # text input with corresponding radioButton
          if line.find("textEditButton") != -1: 
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1] 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., CUSTOM_PORT   
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','')
            inputButton = QLineEdit(self)
            inputButton.setPlaceholderText(var_name)
            radioButton = QRadioButton(button_text)
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              radioButton.setEnabled(False)
              inputButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, radioButton, var_name, requisite, inputButton, None)]

          # text input without a radioButton
          if line.find("textEditBox") != -1: 
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1] 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., CUSTOM_PORT   
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','')
            inputButton = QLineEdit(self)
            inputButton.setPlaceholderText(var_name)
            initial_setting = line.split('" ')[1].split(' ')[2]
            button = QLabel(button_text)
            if initial_setting == "off":
              inputButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, button, var_name, requisite, inputButton, None)]

          # file input (text box)
          if line.find("fileInput") != -1:
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1] #text inside the button ('Choose file...')
            var_name = line.split('" ')[1].split(' ')[0] #e.g., FILE_INPUT
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','') # can be True or False
            inputButton = QLineEdit(self)
            inputButton.setPlaceholderText(var_name)
            pushButton = QPushButton(button_text)
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              pushButton.setEnabled(False)
              inputButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, pushButton, var_name, requisite, inputButton, None)]

          # checkbox/toggleButton input
          if line.find("toggleButton") != -1:
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1]
            var_name = line.split('" ')[1].split(' ')[0]
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','') # last element, True or False
            var_value = line.split('" ')[1].split(' ')[1].split('/')
            checkBox = QCheckBox(button_text)
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              checkBox.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, checkBox, var_name, requisite, None, var_value)]

          # dropDown lists input
          if line.find("dropdownList") != -1:
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1]
            var_name = line.split('" ')[1].split(' ')[0] #e.g., FILE_INPUT
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','') # can be True or False
            var_value = line.split('" ')[1].split(' ')[1].split('/')
            dropdownButton = QComboBox(self)
            for _value in var_value:
              dropdownButton.addItem(_value)
            dropdownButton.move(50,250)
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              dropdownButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, dropdownButton, var_name, requisite, None, var_value)]
            
          # push button input
          if line.find("pushButton") != -1:
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] 
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','') # can be True or False
            var_value = line.split('" ')[1].split(' ')[1]
            pixmap = QPixmap('/home/laura/teamcode/appsAway/demos/synthesis/audioicon.png')
            pushButton = QPushButton(button_text)
            pushButton.setGeometry(200, 150, 50, 50) 
            pushButton.setIcon(QIcon(pixmap))
            pushButton.setIconSize(QSize(50, 50))
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              pushButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, pushButton, var_name, requisite, None, var_value)]

          # audio button input
          if line.find("audioInput") != -1:
            button_type = line.split(' ')[0]
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] 
            requisite = line.split(" ")[-1].replace('\n', '').replace('\r','').replace(' ','') # can be True or False
            var_value = line.split('" ')[1].split(' ')[1]
            pixmap = QPixmap('/home/laura/teamcode/appsAway/demos/synthesis/audioicon.png')
            pushButton = QPushButton(button_text)
            pushButton.setGeometry(200, 150, 50, 50) 
            pushButton.setIcon(QIcon(pixmap))
            pushButton.setIconSize(QSize(50, 50))
            initial_setting = line.split('" ')[1].split(' ')[2]
            if initial_setting == "off":
              pushButton.setEnabled(False)
            self.button_list = self.button_list + [optionButton(button_type, pushButton, var_name, requisite, None, var_value)]

          # this will add the dependencies to the respective buttons in the class
          # dependencies should be written in the following format: "Dependency - INPUT_FILE - GOOGLE_INPUT on on - ..."
          if line.find("Dependency") != -1:
            dependency_list = line.replace('\n', '').split(' - ')
            for button in self.button_list:
              if button.varName == dependency_list[1]:
                for dep in range(2, len(dependency_list)):
                  temp_dep = dependency_list[dep].split(' ')
                  if temp_dep[1].find('[') != -1:
                    temp_dep[1]=temp_dep[1].replace('[','').replace(']','').split('/')
                  if temp_dep[2].find('[') != -1:
                    temp_dep[2] = temp_dep[2].replace('[','').replace(']','').split(',')
                  button.dependencies = button.dependencies + [[temp_dep[0], temp_dep[1], temp_dep[2]]]


        self.pushUpdateButton = QPushButton("Everything is Up to Date!")
        self.pushStartButton = QPushButton("Start the Application")
        self.pushStopButton = QPushButton("Stop the Application")

        os.chdir(os.environ.get('HOME') + "/teamcode/appsAway/scripts/")
        if os.path.isfile("PIPE"):
          os.remove("PIPE")

        self.timer = QTimer(self)

        self.createTopGroupBox()
        self.createBottomLeftGroupBox()
        self.createBottomRightGroupBox()

        self.timer.timeout.connect(self.checkForUpdates)
        self.timer.start(300000)  


        self.createProgressBar()
        self.event_handler = MyHandler(self.progressBar)
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

          # if this is the first radio button, we set it to true, and only this one
          if buttonOption.varType == 'radioButton' and not found_radio:
            layout.addWidget(buttonOption.button)
            buttonOption.button.setChecked(True)
            buttonOption.button.clicked.connect(self.on_click(buttonOption))
            found_radio = True 

          # This adds the radiobutton and the corresponding text box
          if buttonOption.varType == 'textEditButton':
            layout.addWidget(buttonOption.button)
            layout.addWidget(buttonOption.inputBox)
            buttonOption.button.clicked.connect(self.on_click(buttonOption))
            buttonOption.inputBox.textChanged.connect(self.checkToggleState(buttonOption))

          # This adds the radiobutton and the corresponding text box
          if buttonOption.varType == 'textEditBox':
            layout.addWidget(buttonOption.button)
            layout.addWidget(buttonOption.inputBox)
            buttonOption.inputBox.textChanged.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'fileInput':
            layout.addWidget(buttonOption.button)
            layout.addWidget(buttonOption.inputBox)
            buttonOption.button.clicked.connect(self.openFile(buttonOption))

          if buttonOption.varType == 'toggleButton':
            layout.addWidget(buttonOption.button)
            buttonOption.button.stateChanged.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'dropdownList':
            layout.addWidget(buttonOption.button)
            buttonOption.button.activated.connect(self.checkToggleState(buttonOption))

          if buttonOption.varType == 'audioInput':
            layout.addWidget(buttonOption.button)
            buttonOption.button.clicked.connect(self.playAudio())

        # now we check the dependencies for all buttons, and enable/disable buttons accordingly
        for buttonOption in self.button_list:
          self.checkDependencies(buttonOption)          

        layout.addStretch(1)
        self.bottomRightGroupBox.setLayout(layout)   


    # function to check all dependencies and verify if button should be enabled or not
    def checkDependencies(self, buttonOption):
      for dependency in buttonOption.dependencies:
        for button in self.button_list:
          if button != buttonOption:
            if button.varName == dependency[0]:
              if ((button.varType == "radioButton" or button.varType == "toggleButton") and ((dependency[1] == "selected" and button.button.isChecked()) or (dependency[1] == "unselected" and not button.button.isChecked()))) or ((button.varType == "textEditBox" or (button.varType == "textEditButton" and button.button.isChecked())) and button.inputBox.text() == dependency[1]) or (button.varType == "fileInput" and button.inputBox.text() != "") or (button.varType == "dropdownList" and (button.button.currentText() in dependency[1])):
                  if type(dependency[2]) == list:
                    dep_temp = dependency[2][dependency[1].index(button.button.currentText())] # we want the set of options corresponding to the correct trigger
                    dep_list = dep_temp.split('/')
                    if buttonOption.varType == 'dropdownList': # we change the options of the button dropwdown
                      buttonOption.button.clear()
                      for option in dep_list:
                        buttonOption.button.addItem(option)
                  elif dependency[2] == 'enable':
                    if buttonOption.button != None:
                      buttonOption.button.setEnabled(True)
                    if buttonOption.inputBox != None:
                      buttonOption.inputBox.setEnabled(True)
                  elif dependency[2] == 'disable':
                    if buttonOption.button != None:
                      buttonOption.button.setEnabled(False)
                    if buttonOption.inputBox != None:
                      buttonOption.inputBox.setEnabled(False)
                    return "disabled" # if the button is disabled by one single option, we can ignore all the enable options elsewhere
                  else: # if it was none of these cases, we keep it disabled
                    return "disabled" # if the button is disabled by one single option, we can ignore all the enable options elsewhere
                      
              else: # if the requirement is not met, the button is disabled
                if buttonOption.button != None:
                  buttonOption.button.setEnabled(False)
                if buttonOption.inputBox != None:
                  buttonOption.inputBox.setEnabled(False)
                return "disabled" # if the button is disabled by one single option, we can ignore all the enable options elsewhere
#The function above basically enables a button unless some dependency fails

    def checkRequirements(self):
      for button in self.button_list:
        if button.is_required == "True":
          if button.varType == 'radioButton' or button.varType == 'toggleButton':
            if not button.button.isChecked():
              self.pushStartButton.setEnabled(False)
              return "disabled"

          if button.varType == 'textEditBox':
            if button.inputBox.text() == "" or button.inputBox.text() == button.inputBox.placeholderText():
              self.pushStartButton.setEnabled(False)
              return "disabled"       
       
          if button.varType == 'textEditButton':
            if not button.button.isChecked() and (button.inputBox.text() == "" or button.inputBox.text() == button.inputBox.placeholderText()):
              self.pushStartButton.setEnabled(False)
              return "disabled"
    
          if button.varType == 'dropdownList':
            if button.button.currentText() == "" or button.button.text() == button.button.placeholderText():
              self.pushStartButton.setEnabled(False)
              return "disabled"
              
          if button.varType == 'fileInput':
            if button.inputBox.text() == "":
              self.pushStartButton.setEnabled(False)
              return "disabled"
      self.pushStartButton.setEnabled(True)
          
    
    @pyqtSlot()
    def checkToggleState(self,buttonOption):
      def checkButtonState():
        for button in self.button_list: # check the status of all buttons
          self.checkDependencies(button)
          self.checkRequirements()
      return checkButtonState

    @pyqtSlot()
    def playAudio(self):
      def play():
        sel_voice=[el.button.currentText() for el in list(filter(lambda x: x.varType == 'voiceNameInput', self.button_list)) ] #to avoid another for loop on all the buttons, we do a filter 
        sel_lang=[el.button.currentText() for el in list(filter(lambda x: x.varType == 'languageSynthesisInput', self.button_list)) ] #here we have the selected voice
        
        pygame.mixer.pre_init(24000, -16, 1, 2048)
        pygame.init()
        mixer.init()
        mixer.music.load('/home/laura/teamcode/appsAway/demos/synthesis/Archive/'+ sel_lang[0] + '_' + sel_voice[0] + '.mp3')
        mixer.music.play()
        mixer.stop()
        self.checkRequirements()
      return play


    @pyqtSlot()
    def openFile(self, buttonOption):
      def takeFile():
        filename, _ = QFileDialog.getOpenFileName(self, "Choose file", "/home", "File extension Json (*.json)")

        buttonOption.inputBox.setText(filename)
        self.checkRequirements()

      return takeFile


    @pyqtSlot()
    def on_click(self, buttonOption):
      def setEnable():
        if buttonOption.inputBox != None:
          buttonOption.inputBox.setEnabled(True)
        self.disableAllOthers(buttonOption)
        self.checkRequirements()
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
        
        # if there are requisites, the start application button can be enabled after satisfying all the requisites
        for b in self.button_list:
          if b.is_required.find("True") != -1: 
            self.pushStartButton.setEnabled(False)
    
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

        for buttonOption in self.button_list:
          if buttonOption.button != None:
            buttonOption.button.setEnabled(False)
          if buttonOption.inputBox != None:
            buttonOption.inputBox.setEnabled(False)

        PAUSED = False
        
        elapsedTime = QElapsedTimer()
        elapsedTime.start()

        self.pushStopButton.setEnabled(True)

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
        os.chdir(os.environ.get('HOME') + "/teamcode/appsAway/scripts/ansible_setup")
        rc = subprocess.call("./setup_hosts_ini.sh")
        self.ansible = subprocess.Popen(['make', 'prepare'])
        #os.chdir("..") 
        os.chdir(os.environ.get('HOME') + "/teamcode/appsAway/scripts/")

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
                  file_input = buttonOption.inputBox.text().split('/')[-1]   # filename
                  file_input_path = buttonOption.inputBox.text()             # full path to filename
                  file_input_path = file_input_path[:file_input_path.rfind('/')]  # file path without the filename          
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
        rc = subprocess.call("./appsAway_startApp.sh")
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
        os.chdir(os.environ.get('HOME') + "/teamcode/appsAway/demos/" + os.environ.get('APPSAWAY_APP_NAME'))
        yml_files_default = ["main.yml", "composeGui.yml", "composeHead.yml"]
        yml_files = []


        for yml_file in yml_files_default:
          if os.path.isfile(yml_file):
            print("yml file found: " + yml_file)
            yml_files = yml_files + [yml_file]

        for yml_file in yml_files:
          main_file = open(yml_file, "r")
          main_list = main_file.read().split('\n')

          custom_option_found = False
          end_environ_set = False

          if os.environ.get('APPSAWAY_IMAGES') != '':
            print(os.environ.get('APPSAWAY_IMAGES'))
            list_images = os.environ.get('APPSAWAY_IMAGES').split(' ')
            list_versions = os.environ.get('APPSAWAY_VERSIONS').split(' ')

            for i in range(len(main_list)):
              if main_list[i].find("x-yarp-") != -1:
                if main_list[i+1].find("image") != -1:
                  image_line = main_list[i+1]
                  image_line = image_line.split(':')
                  for f in range(len(list_images)):
                    if image_line[1] == ' '+list_images[f]: # if the name is correct
                      image_line[2] = list_versions[f] # we update the version
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

        os.chdir(os.environ.get('HOME') + "/teamcode/appsAway/scripts/")
          
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
