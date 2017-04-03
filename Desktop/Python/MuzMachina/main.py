from tkinter import Tk
from MuzMachina.GUI import GUI
from MuzMachina.MidiFile import MidiFile

root = Tk()

myMidi = MidiFile()
gui = GUI(root, myMidi)

root.mainloop()
