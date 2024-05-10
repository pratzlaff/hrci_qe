import os
import hz43
import util
import glob
import argparse
import astropy.io.fits
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

from matplotlib import rc, rcParams
rc('text', usetex=True)
#rcParams.update({'font.size': 14})

def main():

    parser = argparse.ArgumentParser(
        description='Plot observed HRC-I/LETG zeroth-order count rates vs HZ 43 model, for two QE versions'
    )
    parser.add_argument('--printem', action='store_true', help='Print obsids, rates, errors.')
    parser.add_argument('-p', '--pdf', help='Save plot to named file.')
    parser.add_argument('v1', help='QE version 1 (e.g., "N0010").')
    parser.add_argument('v2', help='QE version 2 (e.g., "N0011").')
    args = parser.parse_args()

    if args.pdf:
        pdf = PdfPages(args.pdf)
        fig = plt.figure(figsize = (11, 8.5))

    obsid, year = hz43.obsids_years('HRC-I')
    rate, err = util.zeroth_rates(obsid)
    if args.printem:
        for i in range(len(obsid)):
            print('{}\t{}\t{}\t{}'.format(obsid[i], year[i], rate[i], err[i]))

    symbols = { args.v1 : '--', args.v2 : '-' }

    for version in symbols:

        os.environ['ARFPATH'] = '/data/legs/rpete/flight/xcal_hrcsi/arfs/I_qe_' + version

        model_rate = hz43.predicted_rates(obsid)
        ratio = rate / model_rate
        ratio_err = err / model_rate

        plt.plot(year, ratio, symbols[version], label=r'\textrm{'+version+'}')
        plt.errorbar(year, ratio, ratio_err, ecolor='k', fmt='none')

    plt.title(r'\textrm{HZ 43: HRC-I/LETG Zeroth Order}')
    plt.xlabel(r'\textrm{Date}')
    plt.ylabel(r'\textrm{Rate: Observed / Predicted}')

    plt.legend(loc='lower left')

    plt.tight_layout()

    if args.pdf:
        pdf.savefig(fig)
        pdf.close()
    else:
        plt.show()

    plt.close()


if __name__ == '__main__':
    main()
