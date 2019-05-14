# Pihole syncing script

A script to sync between 2 pihole setups. If you are here, I'm assuming
that you would know what a pi-hole is. If not, please have a look [here.](https://pi-hole.net/)
Basically, it's a local DNS server that you can easily install on many
single board computers (such as a Raspberry Pi) which will block ads
on a DNS level, preventing them from reaching client machines, like a
black hole, hence the name, Pi-Hole. (The whole project is full of
Star Trek references, too.)

This script is specifically for people running 2 Pi-hole setups in their
local network. But why run 2 pihole and not just one ?

In the words of reddit user [/u/LandlordTiberius](https://www.reddit.com/r/pihole/comments/9hi5ls/dual_pihole_sync_20/):

> If you are not, you really, really should be. If the primary pihole
> is being updated, undergoing maintenance, running a backup, or simply
> failed you will not have a backup pihole available. This will happen
> on your network. Your only other option during an outage (usually
> unexpected) is to configure your DHCP server to forward to a
> non-pihole, public DNS, thusly defeating why you have pihole installed
> in the first place.
>
> Furthermore, DNS is high availability by design and the
> secondary/tertiary DNS always receives 10%-20% some portion of the DNS
> traffic and if configured with a public DNS IP, your devices will be
> bypassing the safety of pihole blocking. If you are running a single
> pihole and have that pihole listed as the only DNS entry in your DHCP
> setting, all devices on your network will immediately be unable to
> resolve DNS if that pihole goes offline.
>
> I recommend running a PI3 as your primary and a PI3/PI2/ZeroW as
> your secondary. PI2/ZeroW is more than sufficient as a secondary
> and emergency failover.

## What you need to do

Ideally, the script is for people having a good router as their main DHCP,
and not letting their Pi-hole serving as the DHCP server.

### Assumptions

- All of the process will be running either on the default pi user, or the root user.
- ssh on the piholes will be enabled, and by "logging in" in this context, it will be by ssh. If something can be done by the pi-hole web interface, it will be stated explicitly.
- The ssh keys will be created by using default values, and will be named `id_rsa` for the private key, and `id_rsa.pub` for the public key.
- Also, from this point on, the primary pihole will be referred to as "the main pihole" while the fallback/backup pihole will be referred to as "the other pihole".
- Installed command line programs: `git`, and a text editor `(nano, vim, emacs...)`

### Part 1: For people running Pi-Hole as their DHCP server

Disclaimer: Personally, I don't do this on my own pi-holes, and this
part of the instruction is taken from reddit user /u/jvinch76 (see below),
so I cannot vouch for the correctness of the script.

You will need to add another file to `/etc/dnsmasq.d` on your pihole,
and after that you will need to cycle the pihole service. It differs a bit
by the device you are using, but on a Raspberry Pi, the process should look
like so:

```bash
sudo su
cd /etc/dnsmasq.d
touch 05-failoverdns.conf # This file name can be changed according to your system
echo "DHCP-option=option:dns-server,<[YOUR.MAIN.PIHOLE.IP],[YOUR.OTHER.PIHOLE.IP]" > 05-failoverdns.conf
# Remember to replace the [] with the correct IP addresses, without the [ ]
```

### Part 2: Setting up access for the pi-holes

#### Part 2a: Set up root access

1. Login to the primary pihole.
2. Edit the sshd_config file using your favorite text editor (Mine is vim). `sudo vim /etc/sshd_config`
3. Find the `#PermitRootLogin prohibit-password` and change it to `PermitRootLogin without-password`. This is done so that it would allow root access for ssh with public key authentication. Read more about [ssh login permissions here](https://askubuntu.com/questions/449364/what-does-without-password-mean-in-sshd-config-file)
4. Save and quit.
5. Restart the ssh services. `sudo /etc/init.d/ssh restart`
6. Login to the other pihole and repeat step 2-5.

#### Creating ssh keys

## Credits

I did not come up with this script on my own. Rather, it's a contribution
from many reddit users, and a lot I would love to give my thanks to

- /u/jvinch76 for creating [the first version](https://www.reddit.com/r/pihole/comments/9gw6hx/sync_two_piholes_bash_script/).
- /u/LandlordTiberius for creating [version 2.0 and 2.1](https://www.reddit.com/r/pihole/comments/9hi5ls/dual_pihole_sync_20/).
- /u/ShawnEngland a.k.a [@icemansid](https://github.com/icemansid) for creating [version 2.1.1](https://github.com/icemansid/pihole-sync/blob/master/SyncForDummies), with guide to setup the root user.