import astropy.io.fits
import numpy as np
import argparse

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from  matplotlib import rc
rc('text', usetex=True)

def eefrac_interpol(w, widths, eefracs):
    i0 = np.where(widths-w < 0)[0][-1]
    i1 = i0 + 1

    frac = (w-widths[i0]) / (widths[i1]-widths[i0])

    return eefracs[i0] + frac * (eefracs[i1]-eefracs[i0])

def get_eefracs(lsfparm, width):
    hdulist = astropy.io.fits.open(lsfparm)
    data = hdulist[1].data

    ee_fracs = data.field('ee_fracs')[0]
    widths = data.field('widths')[0]
    lambdas = data.field('lambdas')[0]

    return data.field('lambdas')[0], eefrac_interpol(width, data.field('widths')[0], data.field('ee_fracs')[0])

def main():

    parser = argparse.ArgumentParser(description='Write ratio of new/old HRC-I/LETG extraction efficiencies.')

    parser.add_argument('--old', default='/data/legs/rpete/flight/extraction_efficiency/hrcs_leg_lsfparm_N0004/hrcsleg1D1999-07-22lsfparmN0003.fits', help='"Old" lsfparm file.')
    parser.add_argument('--new', default='/data/legs/rpete/flight/extraction_efficiency/hrcs_leg_lsfparm_N0004/hrcsleg1D1999-07-22lsfparmN0004.fits', help='"Old" lsfparm file.')
    parser.add_argument('--width', default=0.004, help='Extraction width. Default is 0.004 degrees.')
    parser.add_argument('--pdf', help='Write plot to the given filename.')
    parser.add_argument('--outfile', default='new_old_ratio.txt', help='Output text file name.')

    args = parser.parse_args()

    lambdas, old_pos = get_eefracs(args.old, args.width)
    jnk, new_pos = get_eefracs(args.new, args.width)

    ratio_pos = new_pos/old_pos

    args.old = args.old.replace('leg1D', 'leg-1D')
    args.new = args.new.replace('leg1D', 'leg-1D')

    jnk, old_neg = get_eefracs(args.old, args.width)
    jnk, new_neg = get_eefracs(args.new, args.width)

    ratio_neg = new_neg/old_neg

    if args.pdf:
        pdf = PdfPages(args.pdf)
        fig = plt.figure(figsize=(11, 8.5))

    plt.plot(lambdas, ratio_pos, '-k', label='TG\_M = +1')
    plt.plot(lambdas, ratio_neg, '-r', label='TG\_M = -1')
    plt.legend(loc='lower left', fontsize=10)

    np.savetxt(args.outfile,
               np.transpose([lambdas, ratio_neg, ratio_pos]),
               fmt=['%4g', '%4g', '%4g'],
               header='Ang\t-new/-old\t+new/+old\nN\tN\tN',
               delimiter='\t')


#    plt.xlim(0, 80)
#    plt.ylim(0.8, 0.95)
    plt.ylabel(r'$\textrm{New/Old Spectral Extraction Efficiency Ratio}$')
    plt.xlabel(r'$\textrm{Wavelength (\AA)}$')

    plt.tight_layout()

    if args.pdf:
        pdf.savefig(fig)
        pdf.close()

    plt.show()


    plt.close()
    

if __name__ == '__main__':
    main()
