import astropy.io.fits
import numpy as np
import argparse
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

import matplotlib
matplotlib.rc('text', usetex=True)

def read_qe(qefile, hdunum, args):
    hdulist = astropy.io.fits.open(qefile)
    data = hdulist[hdunum].data

    qecol = 'qe'
    if args.vinay:
        qecol = 'newqe'

    energy, qe = data.field('energy'), data.field(qecol)
    hdulist.close()

    if args.vinay:
        energy = energy[0]
        qe = qe[0]

    return energy, qe

def main():
    parser = argparse.ArgumentParser(
        description='Compare HRC-I QE files, plotting new/old.'
    )
    parser.add_argument('-y', '--ylabel', help='Y axis label', default=r'\textrm{New / Old}')
    parser.add_argument('-t', '--title', help='Plot title', default=r'\textrm{HRC-I QE Ratio}')
    parser.add_argument('-o', '--outfile', help='Output file name')
    parser.add_argument('-v', '--vinay', action='store_true', help="Columns are in Vinay's format.")
    parser.add_argument('old')
    parser.add_argument('new')
    args = parser.parse_args()

    e1, qe1 = read_qe(args.old, 1, args)
    e2, qe2 = read_qe(args.new, 1, args)

    ratio = qe2 / np.interp(e2, e1, qe1)
    wav = 12.39854 / e2
    plt.plot(e2, ratio)
    plt.xlabel(r'\textrm{Wavelength (\AA)}')
    plt.ylabel(args.ylabel)
    plt.title(args.title)

    plt.tight_layout()

    if (args.outfile): plt.savefig(args.outfile)
    else: plt.show()

    plt.close()



if __name__ == '__main__':
    main()
