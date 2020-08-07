from fbs_runtime.application_context.PyQt5 import ApplicationContext
from PyQt5.QtCore import QDateTime, Qt, QTimer, QElapsedTimer
from PyQt5.QtWidgets import (QApplication, QCheckBox, QComboBox, QDateTimeEdit,
        QDial, QDialog, QGridLayout, QGroupBox, QHBoxLayout, QLabel, QLineEdit,
        QProgressBar, QPushButton, QRadioButton, QScrollBar, QSizePolicy,
        QSlider, QSpinBox, QStyleFactory, QTableWidget, QTabWidget, QTextEdit,
        QVBoxLayout, QWidget, QLineEdit)

from PyQt5.QtGui import QIcon, QPixmap
from PyQt5.QtCore import pyqtSlot

import sys
import time
import subprocess
import os

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

global PAUSED
PAUSED = True

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

        self.gui_dir = os.getcwd()
        print(self.gui_dir)

        self.textEdit = ""
        self.textEdit_name = ""

        # read from .ini file here
        self.button_name_list = []
        conf_file = open(self.gui_dir + "/gui_conf.ini", "r")
        for line in conf_file:
          if line.find("title") != -1:
            self.title = line.split('"')[1]
          if line.find("ImageName") != -1:
            self.image = self.gui_dir + "/" + line.split('"')[1]
          if line.find("radioButton") != -1:
            self.button_name_list = self.button_name_list + [line.split('"')[1]]
          if line.find("textEdit") != -1:
            self.textEdit_name = line.split('"')[1]
            self.button_name_list = self.button_name_list + [line.split('"')[1]]

        # try to make a list of buttons so we can have multiple

        self.pushUpdateButton = QPushButton("Everything is Up to Date!")
        self.pushStartButton = QPushButton("Start the Application")
        self.pushStopButton = QPushButton("Stop the Application")

        for button_name in self.button_name_list:
          self.button_list = self.button_list + [QRadioButton(button_name)]

        if line.find("textEdit") != -1:
          self.textEdit = QLineEdit(self)

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
          self.button_list[0].setChecked(True)

        self.textEdit.setText('/your/custom/port')

        layout = QVBoxLayout()
        for button in self.button_list:
          layout.addWidget(button)
        
        self.textEdit.setEnabled(False)
        layout.addWidget(self.textEdit)

        layout.addStretch(1)
        self.bottomRightGroupBox.setLayout(layout)   

        self.button_list[len(self.button_list)-1].clicked.connect(self.on_click) 

    @pyqtSlot()
    def on_click(self):
        self.textEdit.setEnabled(True)
        textboxValue = self.textEdit.text()
        print("The custom port is:" + textboxValue)

    def createBottomLeftGroupBox(self):
        self.bottomLeftGroupBox = QGroupBox("Application")

        self.bottomLeftGroupBox.setAlignment(Qt.AlignHCenter)
        
        self.pushStartButton.setDefault(True)
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

        for button in self.button_list:
          button.setEnabled(False)

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
        for button in self.button_list:
            if (button.isChecked()):
              print(button.text()+" is selected")

              # we set the environment variables here. 
              os.environ['APPSAWAY_ROBOT_MODEL'] = button.text().split(" ")[0]
              os.environ['APPSAWAY_OPTIONS'] = button.text()

        self.setupEnvironment()
        rc = subprocess.call("./appsAway_startApp.sh")
        #self.rc = subprocess.Popen("./appsAway_startApp.sh", stdout=subprocess.PIPE, shell=True)
    
    def stopApplication(self):
        global PAUSED
        print("stopping application\n\n")
        self.pushStartButton.setEnabled(True)
        self.pushStopButton.setEnabled(False)
        self.timer.stop()  
        self.progressBar.setValue(0)
        PAUSED = True

        for button in self.button_list:
          button.setEnabled(True)

        rc = subprocess.call("./appsAway_stopApp.sh")
        #self.rc = subprocess.Popen("./appsAway_stopApp.sh")

    def setupEnvironment(self):
        os.chdir(os.environ.get('APPSAWAY_APP_PATH'))

        main_file = open("main.yml", "r")
        main_list = main_file.read().split('\n')
        for i in range(len(main_list)):
          if main_list[i].find("x-yarp-base") != -1:
            if main_list[i+1].find("image") != -1:
              image_line = main_list[i+1]
              image_line = image_line.split(':')
              image_line[2] = os.environ.get('APPSAWAY_REPO_VERSION') + "_" + os.environ.get('APPSAWAY_REPO_TAG')
              main_list[i+1] = image_line[0] + ':' + image_line[1] + ':' + image_line[2]
          if main_list[i].find("APPSAWAY_OPTIONS") != -1 and os.environ.get('APPSAWAY_OPTIONS') != None:
            main_list[i] = "    - APPSAWAY_OPTIONS=" + "\"" + os.environ.get('APPSAWAY_OPTIONS') + "\""
        main_file.close()
        main_file = open("main.yml", "w")
        for line in main_list:
          main_file.write(line + '\n')
        main_file.close()
        if os.environ.get('APPSAWAY_OPTIONS') != None:
          env_file = open(".env", "w")
          env_file.write("APPSAWAY_OPTIONS=" + os.environ.get('APPSAWAY_OPTIONS'))
          env_file.close()

        os.chdir(os.environ.get('HOME') + "/teamcode/appsAway/scripts/")
          


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
