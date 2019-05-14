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

#### Part 2a: Creating ssh public authentication keys

1. Login to the primary pihole.
2. Create your SSH key by running `ssh-keygen`. Hit enter 3 times to accept the default values. Assuming your keys will now be set up as `id_rsa` and `id_rsa.pub`
3. Copy your public key to the other pihole by running `scp id_rsa.pub pi@[YOUR.OTHER.PIHOLE.IP]:/home/pi/.ssh/primary.pub`
4. Login to the other pihole. This can either be done from the primary pihole, or from your machine. I'd prefer doing it in my own machine so I don't have to go through another layer of connection, making the process faster.
5. Go into the `.ssh` directory by `cd ~/.ssh`
6. Create an `authorized_keys` file
7. Copy the content of the primary pi-hole public key into the `authorized_keys` file.

```bash
# From your machine
ssh pi@[YOUR.MAIN.PIHOLE.IP]

# You should be in the primary pi hole now.
ssh-keygen
# Hit Enter 3 times
scp ~/.ssh/id_rsa.pub pi@[YOUR.OTHER.PIHOLE.IP]:/home/pi/.ssh/primary.pub
exit

#Back to your machine
ssh pi@[YOUR.OTHER.PIHOLE.IP]
cd .ssh
touch authorized_keys
cat primary.pub > authorized_keys # Copy the content of primary.pub into authorized_keys
exit
```

#### Part 2b: Set up root access

1. Login to the primary pihole.
2. Edit the sshd_config file using your favorite text editor (Mine is vim).
3. Find the `#PermitRootLogin prohibit-password` and change it to `PermitRootLogin without-password`. This is done so that it would allow root access for ssh with public key authentication. Read more about [ssh login permissions here](https://askubuntu.com/questions/449364/what-does-without-password-mean-in-sshd-config-file)
4. Save and quit.
5. Restart the ssh services.
6. Login to the other pihole and repeat step 2-5.

```bash
# From your machine
ssh pi@[YOUR.MAIN.PIHOLE.IP]

# You should be in the primary pihole now
sudo vim /etc/sshd_config
# Find the PermitRootLogin line, edit it, save and quit
sudo /etc/init.d/ssh restart
exit

# Do the same with the other pihole
```

#### Part 3: Running the script

1. Login to your primary pi hole.
2. Download the sciprt, or clone the repo in your home directory.
3. Edit the vars in the script to match your settings.
4. Symlink the script to the home directory.
5. Make the script executable
6. Put the script in a cron tab. I personally used the version 2.0+ onwards of running the script every 5 minutes. Do this by putting this line at the end of the script: `*/5 * * * * /bin/bash /home/pi/piholesync.rsync.sh` For setting other intervals, read more [here](https://crontab.guru/every-5-minutes)

```bash
# From your machine
ssh pi@[YOUR.MAIN.PIHOLE.IP]

# You should be in the primary pi hole now.
cd ~
git clone https://github.com/samhwang/pihole-sync.git
cd pihole-sync/
vim piholesync.rsync.sh
# Edit the vars
chmod +x piholesync.rsync.sh
cd ~
ln -s ~/pihole-sync/piholesync.rsync.sh . # Symlinking the script to the main directory. The dot at the end is important

sudo crontab -e
# Scroll to the end of the script
# Put `*/5 * * * * /bin/bash /home/pi/piholesync.rsync.sh` at the end of the script
```

## Versions

- [1.0 - the first version](https://www.reddit.com/r/pihole/comments/9gw6hx/sync_two_piholes_bash_script/) by /u/jvinch76.
- [2.0 - 2.1 - the second version](https://www.reddit.com/r/pihole/comments/9hi5ls/dual_pihole_sync_20/) by /u/LandlordTiberius. Improvements: check for existence of files before rsync and skip if not present, allow for remote command to be run without password by adding ssh keys to remote host no longer require hard coding password in this script, HAPASS removed.
- [2.1.1](https://github.com/icemansid/pihole-sync/blob/master/SyncForDummies) by /u/ShawnEngland a.k.a [@icemansid](https://github.com/icemansid). Improvements: add guide to set up root users.
- [2.1.2](https://github.com/samhwang/pihole-sync) by /u/samhwang [@samhwang](https://github.com/samhwang). Improvements: removing the vars from the script, also enabling rsync access without actually setting up the password for root user, and permitting root only over public key authentication.

## Credits

I did not come up with this script on my own. Rather, it's a contribution
from many reddit users, and a lot I would love to give my thanks to

- /u/jvinch76 for creating the first version.
- /u/LandlordTiberius for creating version 2.0 and 2.1.
- /u/ShawnEngland a.k.a [@icemansid](https://github.com/icemansid) for creating version 2.1.1.