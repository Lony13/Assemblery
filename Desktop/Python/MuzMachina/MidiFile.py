import random
import io
import pygame as pygame
from midiutil.MidiFile import MIDIFile

class MidiFile:
    myMIDI = None
    tempo = 160  # in BMP

    def __init__(self):
        self.binFile = io.BytesIO()
        self.myMIDI = MIDIFile(1)  # One track, defaults to format 1 (tempo track automatically created)

    def createMusic(self, GUI):
        track = 0  # The track to which the note is added
        # channel = 0  # the MIDI channel to assign to the note [0-15]
        time = 0  # in beats
        duration = 1  # in beats
        volume = 100  # 0 - 127

        self.myMIDI.addTrackName(track, time, "Sample Track")
        self.myMIDI.addTempo(track, time, self.tempo)

        instruments = [3, 5, 6, 11, 19, 25, 28, 33, 35, 41, 49, 57, 59, 74, 115, 119]

        for channel in range(16):
            instrument = instruments[channel]   # pick the right instrument
            MIDIFile.addProgramChange(self.myMIDI, 0, channel, 0, instrument)  # change program to new instrument
            for time in range(16):
                if GUI.checkBoxes[16 * channel + time].instate(['selected']):  # check if the button is selected
                    degrees = random.randint(30, 90)   # 0 - 127
                    self.myMIDI.addNote(track, channel, degrees, time*3, duration, volume)
                    self.myMIDI.addNote(track, channel, degrees, time*3 + 1, duration, volume)
                    self.myMIDI.addNote(track, channel, degrees+10, time*3 + 2, duration, volume)

        self.myMIDI.writeFile(self.binFile)

    def startMusic(self):
        pygame.mixer.init()                          # init the pygame.mixer
        music = io.BytesIO(self.binFile.getvalue())  # get value of binFile to music
        pygame.mixer.music.load(music)               # and load the music to te pygame.mixer
        pygame.mixer.music.play(5)                   # start playing

    def stopMusic(self):
        pygame.mixer.music.stop()

    def fasterMusic(self):
        self.tempo += 1
        self.myMIDI.addTempo(0, 0, self.tempo)

    def slowerMusic(self):
        self.tempo -= 1
        self.myMIDI.addTempo(0, 0, self.tempo)