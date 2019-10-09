#!/bin/bash

echo "A qualquer momento se pressionar \"Q\" ou \"q\" o programa aborta"
echo "Any time press q or Q to abort program"
echo ""
echo "Voce quer criar um rootCA ? y/n"
echo "Are you want create your own rootCA? y/n"
read resp
case $resp in
	y|Y)
	echo "Qual o nome do seu ROOTCA/Dominio?"
  echo "What name of your ROOTCA/Domain?"
	read resp
	if [ $resp -eq "q"-o $resp -eq "Q" ]; then
		exit 127
	fi
	echo "O seu rootCA sera gerado com o nome \" $resp \""
  echo "Your rootCA file will be create with name \" $resp \""
  echo "Lembre, uma senha sera solicitada ao fim do processo, eh com ela que vc vai assinar os certificados"
	echo "Don't forget to inform a password to sign all future certificates"
  read wait
  echo "Press any key to continue
  echo "Your rootCA file will be create with name \" $resp \"
  openssl genrsa -des3 -out rootCA-${resp}.key 4096
	openssl req -x509 -new -nodes -key rootCA-${resp}.key -sha256 -days 3650 -out rootCA-${resp}.crt
	;;

	n|N)
	echo "OK, indo para criacao de certificado assinado"
  echo "OK, goes to creation your own domain cert self-signed"
	;;
  
  q|Q)
  exit 127
  ;;
esac

echo ""
echo "Informe o dominio/url completo para compor o nome dos arquivos key, csr e crt"
echo "Inform full domain/url - FQDN to create your cert files key, csr and finally crt"
echo "> _"
read domain
	if [ $resp -eq "q"-o $resp -eq "Q" ]; then
		exit 127
	fi
echo ""
echo "Qual o rootCA que vai assinar o seu certificado?"
echo "Here, what rootCA file will sign your domain certificate?"
echo "\t$(ls root*key|cut -d"." -f1)"
echo "> _"
read cakey
	if [ $resp -eq "q"-o $resp -eq "Q" ]; then
		exit 127
	fi
echo ""
echo "Agora responda as perguntas e o CN deve ser o host.dominio"
echo "Now, answer questions about your certificate, remember, CN field must be your FQDN choosed early."
echo ""
### modo auto assinado - /usr/bin/openssl req -newkey rsa:2048 -nodes -keyout ${domain}.key -out ${domain}.csr
###                      /usr/bin/openssl x509 -signkey ${domain}.key -in ${domain}.csr -req -days 3650 -out ${domain}.crt
openssl req -new -newkey rsa:4098 -nodes -keyout ${domain}.key -out ${domain}.csr
echo ""
echo "Assinando o pedido de certificado ${domain}.csr com o ${cakey} informado"
echo "Signing your csr file with rootCA file choosed"
echo ""
openssl x509 -req -in ${domain}.csr -CA ${cakey}.crt -CAkey ${cakey}.key -CAcreateserial -out ${domain}.crt -days 1500 -sha256
echo ""
echo -en "\nOs arquivos a seguir foram criados/The files was created
     - ${domain}.key - [e sua nao distribua, mas use nos seus servicos como httpd ou nginx]
     - ${domain}.crt - [e o seu certificado propriamente dito]
     - ${domain}.csr - [e o seu cert server request, usado para gerar seu crt, use no seus servicos tb]
"
echo ""
echo "Just for Centos/Redhat distribuition"
echo "Gerando lista de certificados validos nesse servidor - arquivo certificados-daqui.txt"
awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt  > certificados-daqui.txt

echo ""
echo "O arquivo ${cakey}.crt sera importado nessa maquina?"
echo "> _"
read importaroot
case $importaroot in
	s|S)
	cp ${cakey}.crt /etc/pki/ca-trust/source/anchors/
	update-ca-trust extract
	;;
	n|N)
	echo "Confira no extrato do arquivo certificados-daqui.txt se o ${cakey}.crt foi importado"
	;;
esac
echo ""

echo "Para importar para um keystore do java execute o comando abaixo"
echo "$JAVA_HOME/bin/keytool -import -alias <give_it_a_name_here> -keystore $JAVA_HOME/jre/lib/security/cacerts <ou keystore.jks>. -file /root/certificate.cer ou crt"
echo "Provavelmente a senha desse keystore é \"changeit\""
