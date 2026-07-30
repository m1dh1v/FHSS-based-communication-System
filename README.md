# FHSS-based-communication-System

We aim to design and an FHSS based communication system with high hops per second andd implement it on Adalm Pluto SDR.
So far we have made successful simulations of FHSS systems on Simulink and are close to implementing them on SDR.
We are using a bluetooth inspired approach as well as some hybrid methods to achieve high hops per sec.

And Kian is Gay.

I checked on the web and it looks like the higher hop channel (1200 hops/s) does carry few benefits over 3 channels with say 400 hops/s or shd i say OFDM. All of it boils down to how easy it is to predict the pattern. If i get enough time to see the active channel, I'd be able to decrypt the pattern after say 1000 hops, but if hops are too fast to even observe,I'd not know even the active channel and its freq. Without that data, I have no way of knowing the pattern. In OFDM, if hops arent fast enpugh, you can know the pattern for one of the channels, then the other, and then the other. Then the challenge just remains how you recombine the data intercepted. To advantages dono me h pr FHSS zyada secure h and OFDM zyada fast. Ek hybrid system me dono benefits honge but difficulty bhi combine ho jayegi.  
