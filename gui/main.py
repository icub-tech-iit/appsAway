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
    def __init__(self, varType, button, varName, is_required):
        self.varType = varType
        self.button = button
        self.varName = varName
        self.is_required = is_required
    def init_textInput(self, textInput):
        self.textInput = textInput
    #def set_customName(self, customName):
    #    self.customName = customName
    

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

class WidgetGallery(QDialog):
    def __init__(self, parent=None):
        super(WidgetGallery, self).__init__(parent)
        self.label = QLabel(self)

        self.title = "" #"Grasp the Ball Application"
        self.image = "" #'src/main/images/redball.jpg'

        self.rc = None #inits the subprocess
        self.ansible = subprocess.Popen(['true'])

        self.button_list = []
        self.input_list = [] # used to associate button to inputs

        self.gui_dir = os.getcwd()

        self.textEdit = ""
        self.textEdit_name = ""

        # read from .ini file here
        self.button_name_list = []
        global find_startAskInput #to have access from stop Application 
        find_startAskInput = False
        conf_file = open(self.gui_dir + "/gui_conf.ini", "r")
        for line in conf_file:
          if line.find("title") != -1:
            self.title = line.split('"')[1]
          if line.find("ImageName") != -1:
            self.image = self.gui_dir + "/" + line.split('"')[1]
          if line.find("radioButton") != -1:
            button_text = line.split('"')[1] 
            var_name = line.split('" ')[1].split(' ')[0]
            requisite = line.split(" ")[-1]
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QRadioButton(button_text), var_name, requisite)]
          if line.find("textEdit") != -1: # note: if we have only one textEdit button, we are creating a QRadioButton
            button_text = line.split('"')[1] 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., CUSTOM_PORT   
            requisite = line.split(" ")[-1]
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QRadioButton(button_text), var_name, requisite)]
            self.input_list.append(QLineEdit(self))
            self.input_list[-1].setPlaceholderText(var_name)
            #self.button_list[-1].init_textInput(QLineEdit(self))
            #self.button_list[-1].textInput.setPlaceholderText(var_name) #setText("write custom option")
            #self.button_list[-1].set_customName(button_text)
            #self.textEdit_name = button_text
            #self.button_name_list = self.button_name_list + [button_text]
          if line.find("fileInput") != -1:
            button_text = line.split('"')[1] #text inside the button ('Choose file...')
            var_name = line.split('" ')[1].split(' ')[0] #e.g., FILE_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QPushButton(button_text), var_name, requisite)]
            #self.button_list[-1].set_customName(button_text)

            self.input_list.append(QLineEdit(self))
            self.input_list[-1].setPlaceholderText(var_name)
        # try to make a list of buttons so we can have multiple

          if line.find("googleInput") != -1:
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., GOOGLE_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QCheckBox(self), var_name, requisite)]
            self.button_list[-1].button.setText(button_text)

          if line.find("languageSpeechInput") != -1:
            var_name = line.split('" ')[1].split(' ')[0] #e.g., FILE_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QComboBox(self), var_name, requisite)]
            self.button_list[-1].button.setEnabled(False)
            self.button_list[-1].button.addItem("language en-US")
            self.button_list[-1].button.addItem("language it-IT")
            self.button_list[-1].button.move(50, 250)

          if line.find("googleProcessInput") != -1:
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., GOOGLE_PROCESS_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QCheckBox(self), var_name, requisite)]
            self.button_list[-1].button.setText(button_text)


          if line.find("startAskInput") != -1:
            find_startAskInput = True
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., START_ASK_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QCheckBox(self), var_name, requisite)]
            self.button_list[-1].button.setText(button_text)

          if line.find("languageSynthesisInput") != -1:
            var_name = line.split('" ')[1].split(' ')[0] #e.g., LANGUAGE_SYNTHESIS_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QComboBox(self), var_name, requisite)]
            self.button_list[-1].button.setEnabled(False)
            self.button_list[-1].button.addItem("language en-US")
            self.button_list[-1].button.addItem("language it-IT")
            self.button_list[-1].button.addItem("language pt-PT")
            self.button_list[-1].button.addItem("language fr-FR")
            self.button_list[-1].button.addItem("language en-GB")
            self.button_list[-1].button.move(50, 250)

          if line.find("voiceNameInput") != -1:
            var_name = line.split('" ')[1].split(' ')[0] 
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QComboBox(self), var_name, requisite)]
            self.button_list[-1].button.setEnabled(False)
            self.button_list[-1].button.addItem("en-US-Wavenet-A")
            self.button_list[-1].button.addItem("en-US-Wavenet-B")
            self.button_list[-1].button.addItem("en-US-Wavenet-C")
            self.button_list[-1].button.addItem("en-US-Wavenet-D")
            self.button_list[-1].button.addItem("en-US-Wavenet-E")
            self.button_list[-1].button.addItem("en-US-Wavenet-F")
            self.button_list[-1].button.addItem("en-US-Wavenet-G")
            self.button_list[-1].button.addItem("en-US-Wavenet-H")
            self.button_list[-1].button.addItem("en-US-Wavenet-I")
            self.button_list[-1].button.addItem("en-US-Wavenet-J")
            self.button_list[-1].button.move(50, 250)

          if line.find("googleSynthesisInput") != -1:
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] #e.g., GOOGLE_SYNTHESIS_INPUT
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QCheckBox(self), var_name, requisite)]
            self.button_list[-1].button.setText(button_text)

          if line.find("audioInput") != -1:
            button_text = line.split('"')[1] #text inside the button 
            var_name = line.split('" ')[1].split(' ')[0] 
            requisite = line.split(" ")[-1] # can be True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QPushButton(button_text), var_name, requisite)]
            self.button_list[-1].button.setEnabled(False)
            self.button_list[-1].button.setGeometry(200, 150, 50, 50) 
            pixmap = QPixmap('/home/laura/teamcode/appsAway/demos/synthesis/audioicon.png')
            self.button_list[-1].button.setIcon(QIcon(pixmap))
            self.button_list[-1].button.setIconSize(QSize(50, 50))

          #Button to use with toggle options
          if line.find("toggleButton") != -1:
            button_text = line.split('"')[1]
            var_name = line.split('" ')[1].split(' ')[0]
            requisite = line.split(" ")[-1] # last element, True or False
            self.button_list = self.button_list + [optionButton(line.split(' "')[0], QCheckBox(self), var_name, requisite)]
            self.button_list[-1].button.setText(button_text)
        
        for buttonOption in self.button_list: #when we have just googleSpeech and googleSpeechProcess options (speech demo) we want googleSpeech greyed out; when we also have speech-start-ask (synthesis demo) we want speech-start-ask greyed out.
          if (find_startAskInput):
            if buttonOption.varType == 'startAskInput' :
              buttonOption.button.setChecked(True)
              buttonOption.button.setEnabled(False)
          else:
            if buttonOption.varType == 'googleInput' :
              buttonOption.button.setChecked(True)
              buttonOption.button.setEnabled(False)
          if buttonOption.varType == 'toggleButton': # all toggle buttons start unchecked
            buttonOption.button.setChecked(False)
            buttonOption.button.setEnabled(True)


        self.pushUpdateButton = QPushButton("Everything is Up to Date!")
        self.pushStartButton = QPushButton("Start the Application")
        self.pushStopButton = QPushButton("Stop the Application")

        #for button_name in self.button_name_list:
        #  self.button_list = self.button_list + [QRadioButton(button_name)]

        #if line.find("textEdit") != -1:
        #  self.textEdit = QLineEdit(self)

        #os.chdir("../../../scripts/") 
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
        #mainLayout.setRowStretch(0, 1)
        #mainLayout.setRowStretch(1, 1)
        #mainLayout.setColumnStretch(0, 1)
        #mainLayout.setColumnStretch(1, 1)
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
    
    def createBottomRightGroupBox(self):
        self.bottomRightGroupBox = QGroupBox("Application Options")

        self.bottomRightGroupBox.setAlignment(Qt.AlignHCenter)


        if len(self.button_list) >= 1:
          self.button_list[0].button.setChecked(True)

        layout = QVBoxLayout()
        for buttonOption in self.button_list:
          layout.addWidget(buttonOption.button)

          for obj in self.input_list:
            if buttonOption.varName == obj.placeholderText():
              layout.addWidget(obj)

          if buttonOption.varType == 'fileInput':
            buttonOption.button.clicked.connect(self.openFile(buttonOption))

          if buttonOption.varType == 'textEdit':
            buttonOption.button.clicked.connect(self.on_click(buttonOption))
            # buttonOption.textInput.setEnabled(False)
            #layout.addWidget(buttonOption.textInput)
          
          if buttonOption.varType == 'googleInput':
            buttonOption.button.stateChanged.connect(self.checkGoogleButtonState(buttonOption))

          if buttonOption.varType == 'googleSynthesisInput':
            buttonOption.button.stateChanged.connect(self.checkButtonState(buttonOption))

          if buttonOption.varType == 'languageSynthesisInput':
            lang_for_synth = buttonOption.button
            buttonOption.button.activated.connect(self.checkSelectedLanguage(lang_for_synth))

          if buttonOption.varType == 'audioInput':
            buttonOption.button.clicked.connect(self.playAudio())

          

        #if len(self.button_list) >= 1:
        #  if self.button_list[0].varType == 'textEdit':
        #   self.button_list[0].textInput.setEnabled(True)
        #   layout.addWidget(self.button_list[0].textInput)

        layout.addStretch(1)
        self.bottomRightGroupBox.setLayout(layout)   

        #self.button_list[len(self.button_list)-1].clicked.connect(self.on_click) 
  
    #@pyqtSlot()
    #def showItem(self, buttonOption):
    #  def printItem():
        #if buttonOption.varType == 'languageSpeechInput':
    #      print(buttonOption.varType)
    #      print(buttonOption.button)
          #return buttonOption.button.currentText()
    #  return printItem
    

    @pyqtSlot()
    def checkGoogleButtonState(self,buttonOption):
      def checkGoogleState():
        if buttonOption.button.isChecked() : 
          lang_enable = [el.button.setEnabled(True) for el in list(filter(lambda x: x.varType == 'languageSpeechInput', self.button_list))]
        else:
          lang_enable = [el.button.setEnabled(False) for el in list(filter(lambda x: x.varType == 'languageSpeechInput', self.button_list))]
      return checkGoogleState

    @pyqtSlot()
    def checkButtonState(self,buttonOption):
      def checkState():
        if buttonOption.button.isChecked() : 
          lang_enable = [el.button.setEnabled(True) for el in list(filter(lambda x: x.varType == 'languageSynthesisInput', self.button_list))]
          voice_enable = [el.button.setEnabled(True) for el in list(filter(lambda x: x.varType == 'voiceNameInput', self.button_list))]
          audio_enable = [el.button.setEnabled(True) for el in list(filter(lambda x: x.varType == 'audioInput', self.button_list))]
        else:
          lang_enable = [el.button.setEnabled(False) for el in list(filter(lambda x: x.varType == 'languageSynthesisInput', self.button_list))]
          voice_enable = [el.button.setEnabled(False) for el in list(filter(lambda x: x.varType == 'voiceNameInput', self.button_list))]
          audio_enable = [el.button.setEnabled(False) for el in list(filter(lambda x: x.varType == 'audioInput', self.button_list))]
      return checkState

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
      return play

    @pyqtSlot()
    def checkSelectedLanguage(self,lang_for_synth):
      def checkLanguage():
        if lang_for_synth.currentText() == 'language en-US':
          for buttonOption in self.button_list:
            if buttonOption.varType == 'voiceNameInput':
               buttonOption.button.clear()
               buttonOption.button.addItem("en-US-Wavenet-A")
               buttonOption.button.addItem("en-US-Wavenet-B")
               buttonOption.button.addItem("en-US-Wavenet-C")
               buttonOption.button.addItem("en-US-Wavenet-D")
               buttonOption.button.addItem("en-US-Wavenet-E")
               buttonOption.button.addItem("en-US-Wavenet-F")
               buttonOption.button.addItem("en-US-Wavenet-G")
               buttonOption.button.addItem("en-US-Wavenet-H")
               buttonOption.button.addItem("en-US-Wavenet-I")
               buttonOption.button.addItem("en-US-Wavenet-J")
        elif lang_for_synth.currentText() == 'language fr-FR':
          for buttonOption in self.button_list:
            if buttonOption.varType == 'voiceNameInput':
               buttonOption.button.clear()
               buttonOption.button.addItem("fr-FR-Wavenet-A")
               buttonOption.button.addItem("fr-FR-Wavenet-B")
               buttonOption.button.addItem("fr-FR-Wavenet-C")
               buttonOption.button.addItem("fr-FR-Wavenet-D")
        elif lang_for_synth.currentText() == 'language en-GB':
          for buttonOption in self.button_list:
            if buttonOption.varType == 'voiceNameInput':
               buttonOption.button.clear()
               buttonOption.button.addItem("en-GB-Wavenet-A")
               buttonOption.button.addItem("en-GB-Wavenet-B")
               buttonOption.button.addItem("en-GB-Wavenet-C")
               buttonOption.button.addItem("en-GB-Wavenet-D")
        elif lang_for_synth.currentText() == 'language pt-PT':
          for buttonOption in self.button_list:
            if buttonOption.varType == 'voiceNameInput':
               buttonOption.button.clear()
               buttonOption.button.addItem("pt-PT-Wavenet-A")
               buttonOption.button.addItem("pt-PT-Wavenet-B")
               buttonOption.button.addItem("pt-PT-Wavenet-C")
               buttonOption.button.addItem("pt-PT-Wavenet-D")
        else: 
          if lang_for_synth.currentText() == 'language it-IT':
            for buttonOption in self.button_list:
              if buttonOption.varType == 'voiceNameInput':
                buttonOption.button.clear()
                buttonOption.button.addItem("it-IT-Wavenet-A")
                buttonOption.button.addItem("it-IT-Wavenet-B")
                buttonOption.button.addItem("it-IT-Wavenet-C")
                buttonOption.button.addItem("it-IT-Wavenet-D")
      return checkLanguage



    @pyqtSlot()
    def openFile(self, buttonOption):
      def takeFile():
        filename, _ = QFileDialog.getOpenFileName(self, "Choose file", "/home", "File extension Json (*.json)")

        required_satisfied = True
        for filtered_buttonOption in filter(lambda x: x.varType == "fileInput", self.button_list):
          for obj in self.input_list:
            if filtered_buttonOption.varName == obj.placeholderText():
              obj.setText(filename)
            if (obj.text() == ''):
              required_satisfied = False
        if required_satisfied == True:
          self.pushStartButton.setEnabled(True)
      return takeFile


    @pyqtSlot()
    def on_click(self, buttonOption):
      def setEnable():
        for obj in self.input_list:
          if buttonOption.varName == obj.placeholderText():
              obj.setEnabled(True)
        self.disableAllOthers(buttonOption)
        #textboxValue = buttonOption.textInput.text()
        #print("The custom option is:" + textboxValue)
      return setEnable

    def disableAllOthers(self, currentOption):
      for buttonOption in self.button_list:
        if buttonOption.varType == 'textEdit':
          if buttonOption != currentOption:
            for obj in self.input_list:
              if buttonOption.varName == obj.placeholderText():
                obj.setEnabled(False)

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
          buttonOption.button.setEnabled(False)

        #self.bottomRightGroupBox.setEnabled(False)

        PAUSED = False
        
        #self.timer.timeout.connect(self.advanceProgressBar)
        #self.timer.start(100)  

        elapsedTime = QElapsedTimer()
        elapsedTime.start()

        self.pushStopButton.setEnabled(True)

        self.startApplication()

        #while True:
        #    print(elapsedTime.elapsed())
             #if elapsedTime.elapsed() >= 10000:
             #   self.stopProgressBar()
            
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
            #if (buttonOption.button.isChecked()):
            if (buttonOption.button.isEnabled):
              #if buttonOption.varType != 'languageSpeechInput': # Combo has no attribute text
              #  print(buttonOption.button.text()+" is enabled")

              if buttonOption.varType == 'fileInput':
                for obj in self.input_list:
                  if buttonOption.varName == obj.placeholderText():
                    file_input = obj.text().split('/')[-1]   # filename
                    file_input_path = obj.text()             # full path to filename
                    file_input_path = file_input_path[:file_input_path.rfind('/')]  # file path without the filename          
                    os.environ[buttonOption.varName] = file_input
                    os.environ[buttonOption.varName + '_PATH'] = file_input_path
              elif buttonOption.varType == 'languageSpeechInput':
                    #language = self.showItem(buttonOption).split(' ')[1] #to have just it-IT 
                    languageSpeech = buttonOption.button.currentText().split(' ')[1] #to have just it-IT 
                    os.environ[buttonOption.varName] = languageSpeech
              elif buttonOption.varType == 'googleInput':
                  if buttonOption.button.isChecked():
                    os.environ[buttonOption.varName] = "True"
                  else:
                    os.environ[buttonOption.varName] = "False"
              elif buttonOption.varType == 'googleProcessInput':
                  if buttonOption.button.isChecked():
                    os.environ[buttonOption.varName] = "True"
                  else:
                    os.environ[buttonOption.varName] = "False"
              elif buttonOption.varType == 'googleSynthesisInput':
                  if buttonOption.button.isChecked():
                    googleSynthesis_found = True
                    os.environ[buttonOption.varName] = "True"
                  else:
                    os.environ[buttonOption.varName] = "False"
              elif buttonOption.varType == 'toggleButton':
                  if buttonOption.button.isChecked():
                    os.environ[buttonOption.varName] = "true"
                  else:
                    os.environ[buttonOption.varName] = "false"
              elif buttonOption.varType == 'languageSynthesisInput' and googleSynthesis_found:
                  languageSynthesis = buttonOption.button.currentText().split(' ')[1] #to have just it-IT 
                  os.environ[buttonOption.varName] = languageSynthesis
              elif buttonOption.varType == 'voiceNameInput' and googleSynthesis_found:
                  os.environ[buttonOption.varName] = buttonOption.button.currentText()#e.g. en-US-Standard-B
              else:
                # we set the environment variables here. 
                #os.environ['APPSAWAY_OPTIONS'] = buttonOption.button.text()
                if buttonOption.varType == 'textEdit':
                  for obj in self.input_list:
                    if buttonOption.varName == obj.placeholderText():
                      os.environ[buttonOption.varName] = obj.text()

                         #os.environ[buttonOption.customName] = buttonOption.textInput.text()
                  #self.custom_option = buttonOption.customName
         

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

        for b in self.button_list:
          if b.is_required.find("True") != -1: 
            self.pushStartButton.setEnabled(False)

        for buttonOption in self.button_list:
          if buttonOption.is_required.find("True") != -1: 
            self.pushStartButton.setEnabled(False)
          if buttonOption.varType == 'textEdit':
            for obj in self.input_list:
              if buttonOption.varName == obj.placeholderText():
                obj.setText("")#we set the associated QLine object empty 
                os.environ[buttonOption.varName] = obj.text() #we set the CUSTOM_PORT variable empty, otherwise if we restart the application with robot camera the .env will keep the previous value of CUSTOM_PORT and it won't work;
                buttonOption.button.setEnabled(True)
          elif buttonOption.varType == 'googleInput' and find_startAskInput: #if we have speechStartAsk, googleInput is not greyed out 
            buttonOption.button.setChecked(False) #removing tick 
            buttonOption.button.setEnabled(True)
          elif buttonOption.varType == 'googleInput' and not find_startAskInput: #if we do not have speechStartAsk, googleInput is greyed out 
            buttonOption.button.setChecked(True) 
            buttonOption.button.setEnabled(False)
          elif buttonOption.varType == 'googleSynthesisInput':
            buttonOption.button.setChecked(False) 
            buttonOption.button.setEnabled(True)
          elif buttonOption.varType == 'toggleButton':
            buttonOption.button.setChecked(False) 
            buttonOption.button.setEnabled(True)
          elif buttonOption.varType == 'speechStartAsk':
            buttonOption.button.setEnabled(False) #removing tick but keeping greyed out 
          elif buttonOption.varType == 'voiceNameInput':
            buttonOption.button.setEnabled(False) 
          elif buttonOption.varType == 'languageSynthesisInput':
            buttonOption.button.setEnabled(False) 
          elif buttonOption.varType == 'googleProcessInput':
              buttonOption.button.setChecked(False)
              buttonOption.button.setEnabled(True)
          else: # all other unspecified buttons, e.g. radioButton
              buttonOption.button.setEnabled(True)
      

        rc = subprocess.call("./appsAway_stopApp.sh")
        #self.rc = subprocess.Popen("./appsAway_stopApp.sh")

    def setupEnvironment(self):
        #os.chdir(os.environ.get('APPSAWAY_APP_PATH'))
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

          #for i in range(len(main_list)):
          #  if main_list[i].find("x-yarp-base") != -1 or main_list[i].find("x-yarp-head") != -1 or main_list[i].find("x-yarp-gui") != -1:
          #    if main_list[i+1].find("image") != -1:
          #      image_line = main_list[i+1]
          #      image_line = image_line.split(':')
          #      image_line[2] = os.environ.get('APPSAWAY_REPO_VERSION') + "_" + os.environ.get('APPSAWAY_REPO_TAG')
          #      main_list[i+1] = image_line[0] + ':' + image_line[1] + ':' + image_line[2]

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

            #if main_list[i].find("APPSAWAY_OPTIONS") != -1 and os.environ.get('APPSAWAY_OPTIONS') != None:
            #    main_list[i] = "    - APPSAWAY_OPTIONS=" + "\"" + os.environ.get('APPSAWAY_OPTIONS') + "\""
            #if main_list[i].find(self.custom_option) != -1 and os.environ.get(self.custom_option) != None:
            #    main_list[i] = "    - " + self.custom_option + "=" + os.environ.get(self.custom_option)
            #    custom_option_found = True

            # Check if the custom variable has already been set and it overwrites with the new value
            #if not end_environ_set and not custom_option_found:
            #  print('410', main_list[i])
            #  for filtered_buttonOption in filter(lambda x: x.varType == 'fileInput', self.button_list):
            #      if main_list[i].find(filtered_buttonOption.varName) != -1 and os.environ.get(filtered_buttonOption.varName) != None:
            #        main_list[i] = main_list[i][:main_list[i].find('=')]
            #        main_list[i] = main_list[i] + "=" + os.environ.get(filtered_buttonOption.varName)

            #      if main_list[i].find(filtered_buttonOption.varName + '_PATH') != -1 and os.environ.get(filtered_buttonOption.varName + '_PATH') != None:
            #        main_list[i] = main_list[i][:main_list[i].find('=')]
            #        main_list[i] = main_list[i] + "=" + os.environ.get(filtered_buttonOption.varName + '_PATH')
            #        custom_option_found = True

            # if no custom variable has been found it's added to the file
            #if main_list[i].find("volumes") != -1 and not custom_option_found:
            #    print('423', main_list[i])

            #    end_environ_set = True
            #    for filtered_buttonOption in filter(lambda x: x.varType == 'fileInput', self.button_list):
            #        main_list.insert(i, "    - " + filtered_buttonOption.varName + "=" + os.environ.get(filtered_buttonOption.varName))
            #        main_list.insert(i, "    - " + filtered_buttonOption.varName + "_PATH=" + os.environ.get(filtered_buttonOption.varName + '_PATH'))
            #        custom_option_found = True
                    
                #if self.custom_option != "":
                    #main_list.insert(i, "    - " + self.custom_option + "=" + os.environ.get(self.custom_option))
                    #custom_option_found = True

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
        #custom_option_found = False
        # end_environ_set=False

        fileIn_list=list(filter(lambda x: x.varType == 'fileInput', self.button_list)) #list of button of type 'fileInput'
        fileIn_var_list=list(chain.from_iterable((el.varName,el.varName + "_PATH")  for el in fileIn_list)) #for each button of type 'fileInput' we need to add both el.varName (e.g. FILE_INPUT) and el.varName + "_PATH"(e.g. FIND_INPUT_PATH)
        
        textEd_list=list(filter(lambda x: x.varType == 'textEdit', self.button_list)) #list of button of type 'textEdit'
        textEd_var_list=[el.varName for el in textEd_list]#for each button of type 'textEdit' we need to add el.varName (e.g. CUSTOM_PORT)

        language_list=list(filter(lambda x: x.varType == 'languageSpeechInput', self.button_list)) #list of button of type 'languageSpeechInput'
        lanIn_var_list=[el.varName for el in language_list]#for each button of type 'textEdit' we need to add el.varName (e.g. LANGUAGE_SPEECH_INPUT)

        process_list=list(filter(lambda x: x.varType == 'googleProcessInput', self.button_list)) 
        proc_var_list=[el.varName for el in process_list]

        synt_var_list=[el.varName for el in list(filter(lambda x: x.varType == 'googleSynthesisInput', self.button_list)) ]

        spch_var_list=[el.varName for el in list(filter(lambda x: x.varType == 'googleInput', self.button_list)) ]
  
        lanSy_var_list=[el.varName for el in list(filter(lambda x: x.varType == 'languageSynthesisInput', self.button_list)) ]

        voice_var_list=[el.varName for el in list(filter(lambda x: x.varType == 'voiceNameInput', self.button_list)) ]

        
        var_list=["APPSAWAY_OPTIONS"] + fileIn_var_list + textEd_var_list + lanIn_var_list +  proc_var_list + synt_var_list + lanSy_var_list + voice_var_list + spch_var_list #list of enviroment variables

        for button in self.button_list:
          if button.varType == "toggleButton":
            var_list = var_list + [button.varName]

        # Checking if we already have all the environment variables in the .env; if yes we overwrite them, if not we add them 
        for var_l in var_list:
          not_found=True
          for i in range(len(env_list)):
            if env_list[i].find(var_l + "=") != -1 and os.environ.get(var_l) != None:
              env_list[i] = var_l + "=" + os.environ.get(var_l)
              not_found=False 
          if not_found and os.environ.get(var_l) != None:
            env_list.insert(len(env_list), var_l + "=" + os.environ.get(var_l))

          #if env_list[i].find("APPSAWAY_OPTIONS") != -1 and os.environ.get('APPSAWAY_OPTIONS') != None:
           # env_list[i] = "APPSAWAY_OPTIONS=" + os.environ.get('APPSAWAY_OPTIONS')
          #if env_list[i].find(self.custom_option) != -1 and os.environ.get(self.custom_option) != None:
            #env_list[i] = self.custom_option+"="+os.environ.get(self.custom_option)
            #custom_option_found = True
          #if i == len(env_list)-1: #and not custom_option_found:
              #if self.custom_option != "":
                  #env_list.append(self.custom_option + "=" + os.environ.get(self.custom_option))

          #if not end_environ_set:
          #  for filtered_buttonOption in filter(lambda x: x.varType == 'fileInput', self.button_list):
              # Check if the custom variable has already been set and it overwrites with the new value
          #    if env_list[i].find(filtered_buttonOption.varName) != -1 and os.environ.get(filtered_buttonOption.varName) != None:
          #      env_list[i] = filtered_buttonOption.varName + "=" + os.environ.get(filtered_buttonOption.varName)
          #    found = True
          #    else:
                #if no custom variable has been found it's added to the file
          #      env_list.insert(i,filtered_buttonOption.varName + "=" + os.environ.get(filtered_buttonOption.varName))
          #    if env_list[i].find(filtered_buttonOption.varName) != -1 and os.environ.get(filtered_buttonOption.varName) != None:
          #      env_list[i] = filtered_buttonOption.varName + "_PATH=" + os.environ.get(filtered_buttonOption.varName + '_PATH')
          #    else:
          #      env_list.insert(i,filtered_buttonOption.varName + "_PATH=" + os.environ.get(filtered_buttonOption.varName + '_PATH'))
            #end_environ_set=True

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
