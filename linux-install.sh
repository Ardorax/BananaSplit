cmd=( `whereis banana` )
app=${cmd[1]}
user=`whoami`

if [ $user == "root" ]; then
    echo "Please don't run this script as root"
    exit 1
fi

if [ -z $app ]; then
    echo "Installation de BananaSplit."
    sudo touch /usr/bin/banana && sudo chown "$user:$user" /usr/bin/banana && cat ./coding-style.sh > /usr/bin/banana && chmod u+x /usr/bin/banana
else
echo "Mise a jour du script BananaSplit."
    git pull
    cat ./coding-style.sh > /usr/bin/banana
    chmod u+x /usr/bin/banana
fi
