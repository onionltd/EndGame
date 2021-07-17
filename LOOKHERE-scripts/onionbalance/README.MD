Onionbalance is the core of your scalability system. This is what makes all your seperate front onions work as a unified front! 

However it has it's limits. Onion Services have a limit to the amount of introduction points within a specific descriptor they can have and how large the descriptor can be. 

These limits lead to some pretty big problems. 

 1) There is a limit to the amount of fronts a single onion can have. 
 2) Each front can only have a certain amount of introduction points themselves.
 3) Under attack descriptors can become spent before they can be replaced.

"spent" descriptors are when all the introduction points to the onion service are no longer accepting clients. Introduction points have a certain amount of introduction cell requests it will accept before not accepting anymore. These requests are the Tor's main DDOS problem. By specifically requesting tons of introduction cells, which are computationally cheap to do, an attacker can overload an onion service. The only way to protect against this right now is by scaling out.

First read the README.MD from the main directory and install onionbalance to a 2CPU 2GB RAM server seperate from your cluster of fronts. 

After you have installed onionbalance you will need to cd into the directory go to /onionbalance/hs_v3/params.py and change
N_INTROS_PER_INSTANCE = 2 -> N_INTROS_PER_INSTANCE = 1

Save the params.py file and go back to the main onionbalance directory. Run

python3 setup.py install

and then you can setup the configuration with your front's URLs. 

To run onionbalance cd into the onionbalance directory and run:

nohup onionbalance -v info -c config/config.yaml &

This will start onionbalance detacted from the terminal and then put it in the background. Afterwards you can run 

tail -f nohup.out

and see the status of it. You want to see distinct descriptors being pushed.