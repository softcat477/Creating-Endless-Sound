import numpy as np
import librosa
import statistics

fs = 44100
y, sr = librosa.load("airplane_1s.wav", sr=fs)
print (y[43485])
print (y.shape, sr)

print ("mean:{}".format(np.mean(y)))
print ("std:{}".format(np.std(y)))
print ("max:{}".format(np.max(y)))
print ("min:{}".format(np.min(y)))

N=4410
print (N*np.mean(y))

n_old = 0
for i in range(20):
    ran = np.random.rand(N)*44100
    ran = ran.astype(np.int)
    ppos = np.sum(y[ran])
    print ("\t", ppos, '\t', ppos/N, '\t', ppos-n_old)
    n_old = ppos

