#!/bin/bash

figlet SubdomainsF

echo $(tput setaf 9)
read -p " [!] Please enter a domain: " url

if [ ! -d "$url" ]; then
	mkdir $url 
fi
echo "$(tput setaf 7)"


echo
echo " [?] Checks if Go is installed.. "
sleep 1

if which golang >/dev/null; then
    echo " [!] Go is already installed."
else
    echo " [+] Go is not installed. Downloading and installing..."
	wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz >/dev/null 2>&1
	sudo tar -xzf go1.20.4.linux-amd64.tar.gz >/dev/null 2>&1
	sudo mv go /usr/local >/dev/null 2>&1
	export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc
	source ~/.bashrc
	rm -r go1.20.4.linux-amd64.tar.gz
    echo " [!] Go has been downloaded and installed."
fi
echo

echo " [?] Checks if Subjack is installed.. "
if ! command -v subjack &> /dev/null; then
    echo " [+] Subjack is not installed. Downloading and installing..."
	sudo apt install subjack  >/dev/null 2>&1
	echo " [!] Subjack has been downloaded and installed."
else
    echo " [!] Subjack is already installed."
    
fi
echo
echo " [?] Checks if Google-Chrome is installed.. "
sleep 1
if command -v google-chrome-stable >/dev/null; then
    echo " [!] Google Chrome is already installed."
else
    echo " [+] Google Chrome is not installed. Installing..."
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add ->/dev/null 2>&1
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null 2>&1
    sudo apt update >/dev/null 2>&1
    sudo apt install google-chrome-stable -y >/dev/null 2>&1
echo " [!]Google Chrome has been installed."
fi
echo

echo " [?] Checks if Gowitness is installed.. "
sleep 1
if locate gowitness >/dev/null; then
sleep 1
    echo " [!] GoWitness is already installed."
else
    echo " [+] GoWitness is not installed. Downloading..."
	go install github.com/sensepost/gowitness@latest >/dev/null 2>&1
    echo " [!] Gowitness has been downloaded and installed."
fi
echo

echo " [?] Checks if Assetfinder is installed.. "
sleep 1
if which assetfinder >/dev/null; then
	echo " [!] Assetfinder is already installed."
else
    echo " [+] Assetfinder is not installed. Downloading..."
	sudo apt install assetfinder >/dev/null 2>&1
	echo " [!] Assetfinder has been downloaded and installed."
fi

echo
echo " [?] Checks if Httprobe is installed.. "
sleep 1
if which httprobe >/dev/null; then
sleep 1
	echo " [!] Httprobe is already installed."
else
    echo " [+] Httprobe is not installed. Downloading..."
	sudo apt install httprobe >/dev/null 2>&1
	echo " [!] Httprobe has been downloaded and installed."
fi
echo

echo " [+] Harvesting subdomains with Assetfinder .. "
	assetfinder $url >> $url/assets.txt
	cat $url/assets.txt | grep "$url" >> $url/Subdomains.txt
	rm $url/assets.txt
echo " [!] Finding the subdomains in the Assetfinder tool finished. [!] "
echo

echo "$(tput setaf 9) [*] This can be a long time, it takes too long press CNTRL+C "
echo " [!] Harvesting subdomains with Amass .. "
echo $(tput setaf 7)
amass enum -d $url >> $url/Subdomains.txt 
sort -u $url/Subdomains.txt -o $url/Subdomains.txt
echo " [!] Finding the subdomains in the Amass tool finished. [!] "
echo

echo " [+] Probing for alive domains .. "
	cat $url/Subdomains.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> $url/AliveSubdomains.txt
	sort -u $url/AliveSubdomains.txt -o $url/AliveSubdomains.txt
echo " [!] Done .. "
echo

echo " [!] Takes screenshots of the 'Alive' subdomains .."
gowitness file -f $url/AliveSubdomains.txt >/dev/null 2>&1
echo " [*] The screenshots were taken, you can find them on the Screenshots dir"

echo
echo "$(tput setaf 9)[!] Checks Subdomains IP addresses .."
echo "$(tput setaf 7)"
while IFS= read -r subdomain; do
	ip_address=$(host -t A "$subdomain" | awk '/has address/' | cut -d ' ' -f 4)
	echo "[*] Subdomain: $subdomain | [*] IP Address: $ip_address " | tee -a "$url/SubdomainsIPs.txt"
	    
done < "$url/AliveSubdomains.txt"
echo
echo "$(tput setaf 9)[!] Checks if some subdomain are vulnerable .."
echo
subjack -w "$url/AliveSubdomains.txt" -t 50 -timeout 30 -ssl -c /usr/share/subjack/fingerprints.json -v
