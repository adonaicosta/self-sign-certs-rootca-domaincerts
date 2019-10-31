#!/bin/bash

echo "A qualquer momento se pressionar \"Q\" ou \"q\" o programa aborta"
echo ""

echo "Voce quer criar um rootCA ? y/n"
echo -en "> _ "
read resp
case $resp in
        y|Y|S|s)
        echo ""
        echo "Qual o nome do seu ROOTCA/Dominio?"
        echo -en "> _ "
        read resp1
        if [ $resp1 = "q" -o $resp1 = "Q" -o -z $resp1 ]; then
                exit 127
        fi
        echo ""
        echo "O seu rootCA sera gerado com o nome \" rootCA-$resp1 \""
        echo ""
        echo "Lembre, uma senha sera solicitada ao fim do processo, eh com ela que vc vai assinar os certificados"
        echo "Press ENTER..."
        read wait
        openssl genrsa -des3 -out rootCA-${resp1}.key 4096
        rc1=${?}
        if [ $rc1 -ne 0 ]; then
                echo -en "\nErro na criacao da key, abortando\n"
                rm -f rootCA-${resp1}.key
                exit 127
        else
                echo ""
                sleep 3
                echo "Guarde a senha, sera requisitada a cada assinatura de certificado de dominio e no proximo passo"
                echo "A key foi gerada rootCA-${resp1}.key"
                echo "Inicie o input das informacoes da chave"
                echo -en "Press ENTER...\n"
                read wait
        fi
        openssl req -x509 -new -nodes -key rootCA-${resp1}.key -sha256 -days 3650 -out rootCA-${resp1}.crt
        rc2=${?}
        if [ $rc2 -ne 0 ]; then
                echo -en "\nErro na assinatura, abortando"
                rm -f rootCA-${resp1}.key rootCA-${resp1}.crt
                exit 127
        else
                sleep 3
                echo ""
                echo "Arquivo key e crt para o rootCA-${resp1} gerados com sucesso"
                ls -la rootCA-${resp1}*
                echo -en "\nPress ENTER...\n"
                read wait
        fi
        ;;

        n|N)
        echo ""
        echo "OK, indo para criacao de certificado assinado"
        echo "Press ENTER..."
        read wait
        echo ""
        ;;

        *)
        exit 127
        ;;
esac

echo ""
echo "Informe o dominio/url completo para compor o nome dos arquivos key, csr e crt"
echo -en "> _ "
read domain
        if [ $domain = "q" -o $domain = "Q" ]; then
                echo "Abortando a pedido...."
                exit 0
        elif [ !-z $domain ]; then
                echo "Dominio nao informado"
                echo ""
                exit 127
        fi
echo ""
echo "Qual o rootCA que vai assinar o seu certificado?"
echo -en "\n\t$(ls rootCA*key|cut -d"." -f1)\n"
echo -en "> _ "
read cakey
        if [ $cakey = "q" -o $cakey = "Q" ]; then
                echo "Abortando a pedido...."
                exit 127
        elif [ ! -z $cakey ]; then
                echo "CA key nao informada"
                exit 127
        elif [ ! -f "${cakey}.key" ]; then
                echo "Arquivo ${cakey}.key nao existe"
                exit 127
        fi
echo ""
echo "Agora responda as perguntas e o CN deve ser o host.dominio"
echo "Press ENTER..."
read wait
echo ""
### modo auto assinado - /usr/bin/openssl req -newkey rsa:2048 -nodes -keyout ${domain}.key -out ${domain}.csr
###                      /usr/bin/openssl x509 -signkey ${domain}.key -in ${domain}.csr -req -days 3650 -out ${domain}.crt
openssl req -new -newkey rsa:4098 -nodes -keyout ${domain}.key -out ${domain}.csr
echo -en "\n\n"

echo "Assinando o pedido de certificado ${domain}.csr com o ${cakey} informado"
echo "Press ENTER..."
read wait
echo ""
openssl x509 -req -in ${domain}.csr -CA ${cakey}.crt -CAkey ${cakey}.key -CAcreateserial -out ${domain}.crt -days 1500 -sha256
rc=${?}
if [ $rc -ne 0 ]; then
        echo "Erro na assinatura. processo abortado"
        exit 127
fi
echo -en "\n\n"
sleep 3
echo -en "\nOs arquivos a seguir foram criados/The files was created
     - ${domain}.key - [e sua nao distribua, mas use nos seus servicos como httpd ou nginx]
     - ${domain}.crt - [e o seu certificado propriamente dito]
     - ${domain}.csr - [e o seu cert server request, usado para gerar seu crt, use no seus servicos tb]
"
echo -en "\n\n"
grep rhel /etc/os-release > /dev/null 2>&1
rhel=${?}
grep deb /etc/os-release > /dev/null 2>&1
deb=${?}
echo "Gerando lista de certificados validos nesse servidor - arquivo certificados-daqui.txt"

echo "O arquivo ${cakey}.crt sera importado nessa maquina?"
echo -en "> _ "
read importaroot
case $importaroot in
        s|S|y|Y)
        if [ $rhel -eq 0 ]; then 
        cp ${cakey}.crt /etc/pki/ca-trust/source/anchors/
        update-ca-trust enable
        update-ca-trust extract
        elif [ $deb -eq 0 ]; then
        cp ${cakey}.crt /usr/local/share/ca-certificates/
        update-ca-certificates
        else
        echo "SO nao identificado como Debian-like ou RHEL-like"
        fi
        ;;
        *)
        echo -en "\n\nImporte e confira no extrato do arquivo certificados-daqui.txt se o ${cakey}.crt foi importado"
        ;;
esac
if [ $rhel -eq 0 ]; then
  awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt  > certificados-daqui.txt
  sleep 3
elif [ $deb -eq 0 ]; then
  awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt  > certificados-daqui.txt  
  sleep 3
else
  echo "SO nao identificado como RHEL-like ou Debian-like"
fi
echo -en "\n\n"

echo "Para importar para um keystore do java execute o comando abaixo"
echo "$JAVA_HOME/bin/keytool -import -alias <give_it_a_name_here> -keystore $JAVA_HOME/jre/lib/security/cacerts <ou keystore.jks>. -file /root/certificate.cer ou crt"
echo "Provavelmente a senha desse keystore é \"changeit\""

