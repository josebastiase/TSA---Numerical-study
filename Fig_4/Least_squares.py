from scipy.special import kv
import numpy as np
from scipy.optimize import least_squares
from scipy.stats import loguniform

# Properties of the aquifer
freq = 1.932274 # Frequency in days
R_W = 0.2
R_C = 0.2
R = 0.2 # distance from the well m (only for drawdown computation)
B_AQ = 1 # Aquifer depth m
B_LE = 100 # Leaky layer depth m
SKEMPTON = 0.5 # Skempton's coefficient [-]
BULK = 20000000000.0 

def Wang(K_AQ, S_AQ, K_LE, R_C, R_W, B_AQ, B_LE, freq):

    omega = 2 * np.pi * freq

    betta = ((K_LE / (K_AQ * B_AQ * B_LE)) + ((1j * omega * S_AQ * B_AQ) / (K_AQ * B_AQ))) ** 0.5

    argument = (1j * omega * S_AQ * B_AQ) / (1j * omega * S_AQ * B_AQ + K_LE / B_LE)

    xi = 1 + ((1j * omega * R_W) / (2 * K_AQ * B_AQ * betta)) * (kv(0, betta * R_W) / kv(1, betta * R_W)) * (R_C / R_W)**2

    # water level

    h_w = argument / xi

    return np.abs(h_w), np.angle(h_w, deg=True)

 
#%%

def fit_amp_phase(vars):

    K_AQ, S_AQ, K_LE = vars

    Ar, dPhi = Wang(K_AQ, S_AQ, K_LE, R_C, R_W, B_AQ, B_LE, freq)

    # Im not sure why you multiply amp for S_s??
    #res_amp = amp*S_s - Ar
    
    res_amp = amp - Ar
    res_phase = ph - dPhi

    error = np.asarray([res_amp, res_phase])

    return error

# Uncomment the following two lines to test the method. Works nicely with days instead of seconds.
#amp, phase = Wang(1E-3*24*3600, 1E-5, 0, R_C, R_W, B_AQ, B_LE, freq)
#fit =  least_squares(fit_amp_phase, [1E-3*24*3600, 1E-5, 0], bounds=([1e-8*24*3600,1e-8, 0], [1e-2*24*3600,1e-3,1E-16]), xtol=3e-16, ftol=3e-16, gtol=3e-16)
#################
#################
#################

# Now we have to make the loops 

# Define the number of samples and the resolution
numb = 25 # Resolution
no = 500 # number of samples (seed)

res1 = np.zeros((numb, numb))
res2 = np.zeros((numb, numb))
res3 = np.zeros((numb, numb))

phase = np.linspace(90,-90,numb) # Phase range
amplitude = np.logspace(-3,0,numb) # Amplitude range

#Uncomment to test
#phase = np.linspace(-1.40414595254229,-1.40414595254229,1) # Phase range
#amp = np.linspace(0.9974209874047693,0.9974209874047693,1) # Amplitude range

for xu, m in enumerate(phase):
    print(xu)
    for nu, n in enumerate(amplitude):

        ph = m
        amp = n
        
        s_k = loguniform(1E-7, 1E-3).rvs(size=no) * 24*3600
        s_s = loguniform(1E-7, 1E-5).rvs(size=no)
        s_l = loguniform(1E-8, 1E-4).rvs(size=no) * 24*3600

        inv_k = np.zeros((no))
        inv_s = np.zeros((no))
        inv_l = np.zeros((no))

        for i, j in enumerate(s_k):
            fit =  least_squares(fit_amp_phase, (s_k[i], s_s[i], s_l[i]), bounds=([1E-7* 24*3600, 1E-7, 1E-8* 24*3600], [1E-3* 24*3600, 1E-5, 1E-4* 24*3600]), xtol=3e-16, ftol=3e-16, gtol=3e-16)
            
            # Uncomment to test 
            #fit =  least_squares(fit_amp_phase, [1E-7*24*3600, 1E-8, 1E-5*24*3600], bounds=([1e-8*24*3600,1e-8, 1E-8*24*3600], [1e-2*24*3600,1e-3,1E-4*24*3600]), xtol=3e-16, ftol=3e-16, gtol=3e-16)
            
            inv_k[i] = fit.x[0]
            inv_s[i] = fit.x[1]
            inv_l[i] = fit.x[2]
            
        res1[xu,nu] = np.abs((np.abs(inv_k.min())) - (np.abs(inv_k.max())))
        res2[xu,nu] = np.abs((np.abs(inv_s.min())) - (np.abs(inv_s.max())))
        res3[xu,nu] = np.abs((np.abs(inv_l.min())) - (np.abs(inv_l.max())))

    
np.savetxt('wang_2018_ka_25_500_gabriel_ws_2.csv', res1, delimiter=',')
np.savetxt('wang_2018_ss_25_500_gabriel_ws_2.csv', res2, delimiter=',')
np.savetxt('wang_2018_kl_25_500_gabriel_ws_2.csv', res3, delimiter=',')
