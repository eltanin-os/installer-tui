local en =
{
	[".dict"] = "en",
	[".id"] = "English",
	addmount = "Path>",
	addmount_askmkfs = "Create a New Filesystem?",
	adduser_grps = "Groups>",
	adduser_name = "User Name>",
	back = "Back",
	buffer_esc = "> (Press ESC to Exit)",
	buffer_out = "> Output Buffer",
	end_fail = "Something Went Wrong...",
	end_reboot = "Reboot",
	end_success = "Installation Completed Successfully",
	exit = "Exit",
	getpass_err = "The passwords do not match",
	getpass_passwd = "Password>",
	getpass_repeat = "Repeat>",
	install = "Install",
	install_title = "Summary",
	keyboard = "Keyboard",
	keyboard_title = "Select a Keyboard Layout",
	language = "Language",
	language_title = "Select a Language",
	network = "Network",
	network_choose = "Select an Interface",
	network_connect = "Connect",
	network_source = "Install from Network",
	network_title = "Configure Network",
	no = "No",
	options = "Options",
	opts_bootloader = "Install Bootloader",
	opts_network = "Use Remote Packages",
	partitions = "Partitioning",
	partitions_bootloader = "Install Bootloader",
	partitions_choose = "Select a Device",
	partitions_choosetype = "Select a Filesystem Type",
	partitions_mount = "Select Mount Points",
	partitions_prepare = "Prepare Partitions",
	partitions_title = "Partitioning Options",
	steps = "Status",
	steps_mount = "Mount Points Set",
	steps_network = "Network Configured",
	steps_rootpass = "Root Password Set",
	title = "System Installer",
	users = "Users",
	users_add = "Add User",
	users_del = "Delete User",
	users_set_rootpass = "Set Root Password",
	users_title = "Manage User Accounts",
	yes = "Yes",
}

local pt =
{
	[".dict"] = "pt",
	[".id"] = "Português Brasileiro",
	addmount = "Caminho>",
	addmount_askmkfs = "Criar um Novo Sistema de Arquivos?",
	adduser_grps = "Grupos>",
	adduser_name = "Nome de Usuário>",
	back = "Voltar",
	buffer_esc = "> (Pressione ESC para Sair)",
	buffer_out = "> Buffer de Saída",
	end_fail = "Algo Ocorreu de Errado...",
	end_reboot = "Reiniciar",
	end_success = "Instalação Concluída com Sucesso",
	exit = "Sair",
	getpass_err = "As senhas não coincidem",
	getpass_passwd = "Senha>",
	getpass_repeat = "Repetir>",
	install = "Instalar",
	install_title = "Sumário",
	keyboard = "Teclado",
	keyboard_title = "Selecione um Layout do Teclado",
	language = "Idioma",
	language_title = "Selecione um Idioma",
	network = "Rede",
	network_choose = "Selecione uma Interface",
	network_connect = "Conectar",
	network_source = "Instalar da Rede",
	network_title = "Configurar Rede",
	no = "Não",
	options = "Opções",
	opts_bootloader = "Instalar Bootloader",
	opts_network = "Usar Pacotes Remotos",
	partitions = "Partições",
	partitions_bootloader = "Instalar Bootloader",
	partitions_choose = "Selecione um Dispositivo",
	partitions_choosetype = "Selecione um Sistema de Arquivos",
	partitions_mount = "Selecionar Pontos de Montagem",
	partitions_prepare = "Preparar Partições",
	partitions_title = "Opções de Particionamento",
	steps = "Estado",
	steps_mount = "Pontos de Montagem Definidos",
	steps_network = "Rede Configurada",
	steps_rootpass = "Senha de Administrador Definida",
	title = "Instalador de Sistema",
	users = "Usuários",
	users_add = "Adicionar Usuário",
	users_del = "Remover Usuário",
	users_set_rootpass = "Definir Senha de Administrador",
	users_title = "Gerenciar Contas de Usuário",
	yes = "Sim",
}

local languages =
{
	["en"] = en,
	["pt"] = pt,
}

local list =
{
	"en",
	"pt",
}

return function(arg)
	if arg == ":list" then
		return list
	end
	return languages[arg]
end
