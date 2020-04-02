import numpy as np
import argparse

def main():

    parser = argparse.ArgumentParser()

    parser.add_argument("--inputtxt", dest="inputtxt", help="input linearBCV affine matrix file", default=None, required=True)
    parser.add_argument("--savetxt", dest="savetxt",  help="output inverse affine matrix to txt", default=None, required=True)


    options = parser.parse_args()
    d_options = vars(options)
   
    A = np.loadtxt(d_options['inputtxt'])

    B = np.linalg.inv(A)
    np.savetxt(d_options['savetxt'],B)
    
if __name__ == '__main__':
    main()