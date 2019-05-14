#VARS
FILES=(black.list blacklist.txt regex.list whitelist.txt lan.list) #list of files you want to sync
PIHOLEDIR=/etc/pihole #working dir of pihole
PIHOLE2=[YOUR.OTHER.PIHOLE.IP] #IP of 2nd PiHole
HAUSER=pi #user of second pihole
 
#LOOP FOR FILE TRANSFER
RESTART=0 # flag determine if service restart is needed
for FILE in ${FILES[@]}
do
  if [[ -f $PIHOLEDIR/$FILE ]]; then
  RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR --rsync-path="sudo rsync")
    if [[ -n "${RSYNC_COMMAND}" ]]; then
      # rsync copied changes
      RESTART=1 # restart flagged
     # else
       # no changes
     fi
  # else
    # file does not exist, skipping
  fi
done
 
FILE="adlists.list"
RSYNC_COMMAND=$(rsync -ai $PIHOLEDIR/$FILE $HAUSER@$PIHOLE2:$PIHOLEDIR)
if [[ -n "${RSYNC_COMMAND}" ]]; then
  # rsync copied changes, update GRAVITY
  ssh $HAUSER@$PIHOLE2 "sudo -S pihole -g"
# else
  # no changes
fi
 
if [ $RESTART == "1" ]; then
  # INSTALL FILES AND RESTART pihole
  ssh $HAUSER@$PIHOLE2 "sudo -S service pihole-FTL restart"
fi