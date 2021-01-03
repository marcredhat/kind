hostip=$(hostname  -I | cut -f1 -d' ')
echo -e "Your Kind Cluster Information: \n"
echo -e "Ingress Domain: $hostip.nip.io \n"
echo -e "Ingress rules will need to use the IP address of your Linux Host in the Domain name \n"
echo -e "Example:  You have a web server you want to expose using a host called webserver1."
echo -e "          Your ingress rule would use the hostname: webserver1.$hostip.nip.io"
