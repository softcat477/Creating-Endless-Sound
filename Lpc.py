import librosa
import scipy.io.wavfile
import argparse
import numpy as np
import scipy.signal as sig

def getParsere():
    parser = argparse.ArgumentParser()
    parser.add_argument("--in_path", type=str, required=True)
    parser.add_argument("--order", type=int, default=100)
    parser.add_argument("--sec", type=float, default=10.0)

    return parser.parse_args()

def lpc(y, sr, args):
    # LPC coefficients
    coefs = librosa.lpc(y, args.order)

    # White noise
    wn = np.random.uniform(size=int(sr*args.sec))

    # Convolution
    print (coefs.shape)
    print (y.shape)
    y_out = sig.lfilter([1.0], coefs, wn)
    y_out = y_out / np.max(y_out)
    return y_out

if __name__ == "__main__":
    args = getParsere()

    y, sr = librosa.load(args.in_path)
    y_out = lpc(y, sr, args)

    filename = args.in_path.replace(".wav", "_{:.3f}s_P-{:05d}.wav".format(args.sec, args.order))
    print ("Write to {}".format(filename))
    scipy.io.wavfile.write(filename, sr, y_out)