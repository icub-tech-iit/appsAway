from fbs_runtime.application_context.PyQt5 import ApplicationContext
from PyQt5.QtCore import QDateTime, Qt, QTimer, QElapsedTimer
from PyQt5.QtWidgets import (QApplication, QCheckBox, QComboBox, QDateTimeEdit,
        QDial, QDialog, QGridLayout, QGroupBox, QHBoxLayout, QLabel, QLineEdit,
        QProgressBar, QPushButton, QRadioButton, QScrollBar, QSizePolicy,
        QSlider, QSpinBox, QStyleFactory, QTableWidget, QTabWidget, QTextEdit,
        QVBoxLayout, QWidget)

from PyQt5.QtGui import QIcon, QPixmap

import sys
import time
from subprocess import call
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

        self.button_list = []

        # read from .ini file here
        self.button_name_list = []
        conf_file = open("gui_conf.ini", "r")
        for line in conf_file:
          if line.find("title") != -1:
            self.title = line.split('"')[1]
          if line.find("ImageName") != -1:
            self.image = line.split('"')[1]
          if line.find("radioButton") != -1:
            self.button_name_list = self.button_name_list + [line.split('"')[1]]
        


        # try to make a list of buttons so we can have multiple
        self.pushStartButton = QPushButton("Start the Application")
        self.pushStopButton = QPushButton("Stop the Application")

        for button_name in self.button_name_list:
          self.button_list = self.button_list + [QRadioButton(button_name)]

        #for button in self.button_list:
        #  if button.isSelected():
        #    self.button_list[1].label.split(" ")[0]


        self.timer = QTimer(self)

        self.createTopGroupBox()
        self.createBottomLeftGroupBox()
        self.createBottomRightGroupBox()


        os.chdir("../appsAway/scripts/") 
        if os.path.isfile("PIPE"):
          os.remove("PIPE")

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

    #def advanceProgressBar(self):
#
#        print("Trying")
#        if os.path.isfile("PIPE"):
#          pipe_file = open("PIPE", "r")
#          line = pipe_file.readline()
#          curVal = int(line)
#          maxVal = self.progressBar.maximum()
#          self.progressBar.setValue(curVal + (maxVal - curVal) / 100)
#          pipe_file.close()

    def createTopGroupBox(self):
        self.topGroupBox = QGroupBox(self.title)

        self.topGroupBox.setAlignment(Qt.AlignHCenter) 

        layout = QVBoxLayout()
        
        pixmap = QPixmap(self.image)
        self.label.setPixmap(pixmap)
        #self.resize(pixmap.width(),pixmap.height())
        #self.show()
        layout.addWidget(self.label)
        layout.addStretch(1)
        layout.setAlignment(Qt.AlignCenter)
        self.topGroupBox.setLayout(layout)
    
    def createBottomRightGroupBox(self):
        self.bottomRightGroupBox = QGroupBox("Application Options")

        self.bottomRightGroupBox.setAlignment(Qt.AlignHCenter)

        if len(self.button_list) >= 1:
          self.button_list[0].setChecked(True)

        layout = QVBoxLayout()
        for button in self.button_list:
          layout.addWidget(button)

        layout.addStretch(1)
        self.bottomRightGroupBox.setLayout(layout)    

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

    def startApplication(self):
        print("starting application")
        for button in self.button_list:
            if (button.isChecked()):
              print(button.text()+" is selected")
              print("Robot model is " + button.text().split(" ")[0])
              os.environ['APPSAWAY_ROBOT_MODEL'] = button.text().split(" ")[0]


        rc = call("./appsAway_startApp.sh")
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

        rc = call("./appsAway_stopApp.sh")
        #self.rc = subprocess.Popen("./appsAway_stopApp.sh")

    # overload the closing function to close the watchdog
    def exec_(self):
        self.observer.stop()
        self.observer.join()
    

if __name__ == '__main__':
    appctxt = ApplicationContext()
    gallery = WidgetGallery()
    gallery.show()
    sys.exit(appctxt.app.exec_())
