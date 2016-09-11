#!/bin/bash

#------------------------------------------------------------------------------------------#
# Data: 20 de Agosto de 2016
# Criado por: Juliano Santos [x_SHAMAN_x]
# Script: startup.sh
# Descrição: Script para gerenciar aplicativos na inicialização do sistema.
#
# Observações:
#	Além da inserção automática apartir da lista de aplicativos, o usuário também poderá
#	inserir manualmente seus aplicativos/scripts.
#	Na janela principal, clicando com botão direito sobre a lista, as seguintes opções
#	estaram disponiveis.
#	#-----------------#
#	| Adicionar linha |
#	| Deletar linha   |
#	| Duplicar linha  |
#	#-----------------#
#	Ao clicar em 'Adicionar linha', será inserida uma linha em branco no final da lista,
#	onde o usuário poderá clicar duas vezes com o botão esquerdo sobre o campo, para entrar
#	em modo de inserção e inserir suas configurações personalizadas.
#------------------------------------------------------------------------------------------#
# Nome do script
SCRIPT="$(basename "$0")"

# Pacote necessário
if [ ! -x "$(which yad)" ]; then
    echo "$SCRIPT: Erro: 'yad' não instalado."; exit 1; fi

# Suprime mensagens de erro
exec 2>/dev/null

# Se script for interrompido
trap '_exit' INT

# Diretórios
DIR_DESKTOP=/usr/share/applications 
DIR_START=$HOME/.config/autostart

# Cria diretório se ele não existir.
[ ! -d $DIR_START ] && mkdir $DIR_START

# Arquivos temporários
TMP_LIST=$(mktemp --tmpdir list.XXXXXXXXXX)		# Configurações atuais
TMP_SAVE=$(mktemp --tmpdir save.XXXXXXXXXX)		# Alterações

# Limpa arquivos temporários
_exit(){ rm -f $TMP_LIST $TMP_SAVE; exit 0; }

load_conf()
{
	# Remove lista temporária
	rm -f $TMP_LIST
	
	# Verifica se há arquivos .destkop
	if [ "$(ls -A $DIR_START/*.desktop)" ]; then
		# Lê todos os arquivos *.desktop existentes no diretório.
		for file in $DIR_START/*.desktop; do
			# Armazena as informações extraidas do arquivo '$file'.
			Name="$(egrep -m 1 '^[[:blank:]]*Name=' "$file" | cut -d= -f2)"			# Nome do aplicativo
			Comment="$(egrep -m 1 '^[[:blank:]]*Comment=' "$file" | cut -d= -f2)"	# Comentário
			Icon="$(egrep -m 1 '^[[:blank:]]*Icon=' "$file" | cut -d= -f2)"			# Ìcone
			Exec="$(egrep -m 1 '^[[:blank:]]*Exec=' "$file" | cut -d= -f2)"			# Linha de comando

			# Imprime os valores das variaveis, aplicando o padrão de saida com o delimitador.
			# Redireciona a saida para o arquivo 'TMP_LIST' incrementando seu contéudo.
			# Se o valor da variável for nulo, imprime o valor padrão.
			printf "%s|%s|%s|%s\n" "${Icon:-gtk-missing-image}" \
									"${Name:-null}" \
									"${Exec:-/bin/false}" \
									"${Comment:-''}" >> $TMP_LIST		
		done
	fi
}

get_list()
{
		# Lẽ o arquivo 'desktop' dos aplicativos instalados.
		for desk in $DIR_DESKTOP/*.desktop
		do
			# Armazena os valores extraidos do arquivo '$desk'
			Name="$(egrep -m 1 '^[[:blank:]]*Name=' "$desk" | cut -d= -f2)"			# Nome do aplicativo
			Comment="$(egrep -m 1 '^[[:blank:]]*Comment=' "$desk" | cut -d= -f2)"	# Comentário
			Icon="$(egrep -m 1 '^[[:blank:]]*Icon=' "$desk" | cut -d= -f2)"			# Ìcone
			Exec="$(egrep -m 1 '^[[:blank:]]*Exec=' "$desk" | cut -d= -f2)"			# Linha de comando
		
			# Imprime os valores das variaveis, inserindo o delimitador '\n (nova linha)' no final de cada expressão.
			# O delimitador '\n', cria o limite de campo que é lido pelo 'list' que define os items das colunas e
			# redireciona a saida para PIPE do 'for'
			# Se o valor da variável for nulo, imprime o valor padrão.
			printf "%s\n%s\n%s\n%s\n%s\n%s\n" "FALSE" \
												"${Icon:-gtk-missing-image}" \
												"${Icon:-gtk-missing-image}" \
												"${Name:-null}" "${Exec:-/bin/false}" \
												"${Comment:-''}"
			#------ Lista de aplicativos instalados -----#
			#
			# Exibe a janela de aplicativos com 6 colunas, ocultando apenas a coluna '2'
			# Colunas:
			#	1 - Checkbox
			#	2 - Nome do arquivo de ícone
			#	3 - Imagem do ícone
			#	4 - Nome do aplicativo
			#	5 - Linha de comando
			#	6 - Comentário
			#
			# Se clicar em 'OK', redireciona o contéudo das colunas '2,4 até a última' para o arquivo 'TMP_LIST'
			# incrementando seu contéudo.
		done | yad 	--title="Aplicativos" \
					--text="Selecione os aplicativos que deseja adicionar na incialização." \
					--center \
					--width=600 \
					--height=400 \
					--image=gtk-index \
					--list \
					--multiple \
					--tooltip-column=4 \
					--checklist \
					--regex-search \
					--search-column=4 \
					--hide-column=2 \
					--button='Cancelar!gtk-cancel':1 \
					--button='OK!gtk-ok':0 \
					--column="" \
					--column="" \
					--column="":IMG \
					--column="Nome" \
					--column="Comando" \
					--column="Comentário" | cut -d'|' -f2,4- >> $TMP_LIST

}

save_conf()
{
	# Variáveis locais
	local NAME CMD COMMENT ICON FILE

	# Remove todas as entradas
	rm -f $DIR_START/*.desktop
	
	# Lê as alterações
	cat $TMP_SAVE | while read line; do
		# Lê '$line', aplica o delimitador separando os campos e armazenando os valores.
		eval $(awk -F'|' '{printf "ICON=\"%s\" NAME=\"%s\" EXEC=\"%s\" COMMENT=\"%s\"",$1,$3,$4,$5}' <<< "$line")
		NAME=${NAME//[[:punct:]]/ }				# Remove as pontuações do nome
		FILE="$DIR_START/${NAME// /_}.desktop"	# Define o caminho/nome do arquivo, substituindo espaços entre o nome por '_'
		# Cria o arquivo 'desktop' e salva os parãmetros
		cat > "$FILE" << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
Icon=$ICON
Name=$NAME
Comment=$COMMENT
Exec=$EXEC
StartupNotify=true
Terminal=false
EOF
	done
}

del_all()
{
	# Verifica se diretório está vazio e exibe mensagem de notificação
	if [ ! "$(ls -A $DIR_START/*.desktop)" ]; then
		yad --form \
			--center \
			--fixed \
			--timeout=2 \
			--title="Informação" \
			--image=gtk-dialog-info \
			--text="Não há aplicativos na inicialização." \
			--button="OK":0 
	# Se o diretório conter arquivos 'desktop', exibe mensagem de confirmação.
	# Se o usuário clicar em 'sim|0', remove todos os arquivos .desktop e lista temporária.
	elif yad --form \
				--center \
				--fixed \
				--image=gtk-dialog-question \
				--title="Apagar tudo" \
				--text="Essa ação irá excluir todos os aplicativos da inicialização.\nDeseja continuar ?" \
				--button='Sim!gtk-yes':0 \
				--button='Não!gtk-no':1; then rm -f $DIR_START/*.desktop $TMP_LIST; fi
}	
	
main()
{
	#-------- Janela principal -------#
	#
	# Lê as configurações atuais contidas no arquivo '$TMP_LIST', rediciona a saida
	# para o 'while' que lê cada linha, aplicando padrão '\n (nova linha)' no final de cada expressão'
	# que rediciona a saida para o PIPE do 'for' e exibe a janela.
	cat $TMP_LIST | while read line; do
		awk -F'|' '{printf "%s\n%s\n%s\n%s\n%s\n",$1,$1,$2,$3,$4}' <<< $line
	done | yad --width=500 \
				--height=300 \
				--center \
				--fixed \
				--title="Editor de inicialização - [x_SHAMAN_x]" \
				--image="gtk-execute" \
				--text="Adicionar/Remover itens da inicialização do sistema." \
				--button='Aplicativos!gtk-index!Exibe a lista de aplicativos instalados':2 \
				--button='Aplicar!gtk-apply!Aplica todas as alterações.':0 \
				--button='Apagar tudo!gtk-delete!Apaga todos os aplicativos da inicialização.':3 \
				--button='Sair!gtk-quit!Sai do script.':1 \
				--list \
				--tooltip-column=3 \
				--regex-search \
				--editable \
				--print-all \
				--hide-column=1 \
				--column="" \
				--column="":IMG \
				--column="Nome" \
				--column="Comando" \
				--column="Comentário" > $TMP_SAVE	# Se o usuário clicar em 'Aplicar|0', cria o arquivo de alterações 'TMP_SAVE'
	
	# Status
	RETVAL=$?

	# Lẽ status da janela
	case $RETVAL in
			0)
				# Salva as configurações e carrega as alterações
				save_conf
				load_conf
				;;
			2)
				# Exibe a janela de aplicativos instalados.
				get_list
				;;
			3)
				# Apaga aplicativos da inicialização
				del_all
				;;
			1|252)
				# Sai do script
				_exit
				;;
	esac

	# Retorna para a janela principal
	main	
}

# Inicio
load_conf	
main
