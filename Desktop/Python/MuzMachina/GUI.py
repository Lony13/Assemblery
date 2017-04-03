from tkinter import *
from tkinter import messagebox
from tkinter import ttk
import tkinter.filedialog


class GUI:
    def __init__(self, root, myMidi):
        self.myMidi = myMidi
        self.root = root

        instrumentNames = ["Electric Grand Piano", "Electric Piano 1", "Electric Piano 2", "Music Box",
                           "Rock Organ", "Acoustic Guitar", "Electric Guitar", "Acoustic Bass", "Electric Bass",
                           "Violin", "String Ensemble", "Trumpet", "Tuba", "Flute",
                           "Steel Drums", "Synth Drum"]
        # 3, 5, 6, 11, 19, 25, 28, 33, 35, 41, 49, 57, 59, 74, 115, 119

        root.title("Music Machine")
        root.geometry("750x500")

        self.instrumentNamelabels = []
        self.checkBoxes = []

        # Create all instrument names and checkboxes
        for i in range(len(instrumentNames)):
            self.instrumentNamelabels.append(Label(root, text=instrumentNames[i]))
            self.instrumentNamelabels[i].place(x=10, y=10 + (30 * i))

            for j in range(16):
                self.checkBoxes.append(ttk.Checkbutton(root))
                self.checkBoxes[16 * i + j].place(x=120 + (30 * j), y=10 + (30 * i))

        # create all buttons
        startButton = ttk.Button(root, text="Create", command=lambda: self.createMusic())
        startButton.grid(padx=650, pady=10, sticky=W)

        startButton = ttk.Button(root, text="Start", command=lambda: self.startMusic())
        startButton.grid(padx=650, pady=10, sticky=W)

        stopButton = ttk.Button(root, text="Stop", command=lambda: self.stopMusic())
        stopButton.grid(padx=650, pady=10, sticky=W)

        fasterButton = ttk.Button(root, text="Faster", command=lambda: self.fasterMusic())
        fasterButton.grid(padx=650, pady=10, sticky=W)

        slowerButton = ttk.Button(root, text="Slower", command=lambda: self.slowerMusic())
        slowerButton.grid(padx=650, pady=10, sticky=W)

        self.createMenu()

    def createMenu(self):
        theMenu = Menu(self.root)

        # ----- File Menu -----
        fileMenu = Menu(theMenu, tearoff=0)
        fileMenu.add_command(label="Save", accelerator="Ctrl-S", command=self.saveFile)
        fileMenu.add_separator()
        fileMenu.add_command(label="Quit", accelerator="Ctrl-Q", command=self.quitApp)

        theMenu.add_cascade(label="File", menu=fileMenu)

        self.root.bind('<Control-S>', self.saveFile)
        self.root.bind('<Control-s>', self.saveFile)
        self.root.bind('<Control-Q>', self.quitApp)
        self.root.bind('<Control-q>', self.quitApp)

        # ----- Help Menu -----
        helpMenu = Menu(theMenu, tearoff=0)
        helpMenu.add_command(label="About", accelerator="Ctrl+A", comman=self.showAbout)

        theMenu.add_cascade(label="Help", menu=helpMenu)

        self.root.bind('<Control-A>', self.showAbout)
        self.root.bind('<Control-a>', self.showAbout)

        self.root.config(menu=theMenu)

    def createMusic(self):
        self.myMidi.createMusic(self)

    def startMusic(self):
        self.myMidi.startMusic()

    def stopMusic(self):
        self.myMidi.stopMusic()

    def fasterMusic(self):
        self.myMidi.fasterMusic()

    def slowerMusic(self):
        self.myMidi.slowerMusic()

    def saveFile(self, event=None):
        file = tkinter.filedialog.asksaveasfilename(defaultextension=".mid")
        musicFile = open(file, 'wb')
        self.myMidi.myMIDI.writeFile(musicFile)
        musicFile.close()

    @staticmethod
    def showAbout(event=None):
        messagebox.showwarning("About",
                               "This program was created by Wojciech Koczy :)")

    def quitApp(self, event=None):
        self.root.quit()
