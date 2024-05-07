import numpy as np
import matplotlib.pyplot as plt
from matplotlib import rc, rcParams
rc('text', usetex=True)

def main():
    wav, neg, pos = np.loadtxt('new_old_ratio.txt', usecols=(0,1,2), skiprows=2, unpack=True)
    ratio = 0.5 * (neg + pos)

    plt.plot(wav, ratio)
    plt.xlabel(r'$\textrm{Wavelength (\AA)}$')
    plt.ylabel(r'$\textrm{N0004 / N0003 EEFRAC, HRC-I/LETG default region}$')
    plt.tight_layout()
#    plt.show()
    plt.savefig('hrci_eefrac_ratio_N0004_0003.png')

if __name__ == '__main__':
    main()
