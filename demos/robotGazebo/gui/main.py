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

class WidgetGallery(QDialog):
    def __init__(self, parent=None):
        super(WidgetGallery, self).__init__(parent)
        self.label = QLabel(self)

        self.pushStartButton = QPushButton("Start the Application")
        self.pushStopButton = QPushButton("Stop the Application")
        self.radioButton1 = QRadioButton("Red Ball Selection")
        self.radioButton2 = QRadioButton("Green Ball Selection")
        self.radioButton3 = QRadioButton("Blue Ball Selection")

        self.timer = QTimer(self)
        
        self.createTopGroupBox()
        self.createBottomLeftGroupBox()
        self.createBottomRightGroupBox()
        self.createProgressBar()

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

    def advanceProgressBar(self):
        curVal = self.progressBar.value()
        maxVal = self.progressBar.maximum()
        self.progressBar.setValue(curVal + (maxVal - curVal) / 100)

    def createTopGroupBox(self):
        self.topGroupBox = QGroupBox("Grasp the Ball Application")
        layout = QVBoxLayout()
        
        pixmap = QPixmap('src/main/images/redball.jpg')
        self.label.setPixmap(pixmap)
        #self.resize(pixmap.width(),pixmap.height())
        #self.show()
        layout.addWidget(self.label)
        layout.addStretch(1)
        self.topGroupBox.setLayout(layout)
    
    def createBottomRightGroupBox(self):
        self.bottomRightGroupBox = QGroupBox("Application Options")
        self.radioButton1.setChecked(True)

        layout = QVBoxLayout()
        layout.addWidget(self.radioButton1)
        layout.addWidget(self.radioButton2)
        layout.addWidget(self.radioButton3)

        layout.addStretch(1)
        self.bottomRightGroupBox.setLayout(layout)    

    def createBottomLeftGroupBox(self):
        self.bottomLeftGroupBox = QGroupBox("Application")
        
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
        self.progressBar.setRange(0, 10000)
        self.progressBar.setValue(0)
       

    def startProgressBar(self):
        self.pushStartButton.setEnabled(False)

        self.radioButton1.setEnabled(False)
        self.radioButton2.setEnabled(False)
        self.radioButton3.setEnabled(False)

        #self.bottomRightGroupBox.setEnabled(False)
        
        self.timer.timeout.connect(self.advanceProgressBar)
        self.timer.start(1000)  

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
        print ("Current working dir : %s" % os.getcwd())
        str1 = os.getcwd()
        str2 = "/test.sh"
        path = str1 + str2
        print ("THE SCRIPT will run : %s" % path)
        rc = call("./test.sh")
    
    def stopApplication(self):
        print("stopping application\n\n")
        self.pushStartButton.setEnabled(True)
        self.pushStopButton.setEnabled(False)
        self.timer.stop()  
        self.progressBar.setValue(0)
        self.radioButton1.setEnabled(True)
        self.radioButton2.setEnabled(True)
        self.radioButton3.setEnabled(True)

if __name__ == '__main__':
    appctxt = ApplicationContext()
    gallery = WidgetGallery()
    gallery.show()
    sys.exit(appctxt.app.exec_())
