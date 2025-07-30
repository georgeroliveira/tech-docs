Perfeito. Abaixo está a versão reescrita da documentação `README.md` para uso profissional **sem emojis**, com linguagem clara e objetiva, ideal para que até mesmo um estagiário consiga entender, ajustar e executar os scripts com segurança.

---

````markdown
# Cloud SQL Proxy - Scripts de Conexão Automática

Este repositório contém dois scripts automatizados para conexão segura com o Cloud SQL (PostgreSQL) do Google Cloud. Eles são compatíveis com sistemas macOS, Linux e Windows, com autenticação humana via navegador e verificação automática de porta.

## Autor

George Rodrigues de Oliveira  
GitHub: [github.com/georgeroliveira](https://github.com/georgeroliveira)  
Licença: MIT

## Scripts Disponíveis

| Arquivo                      | Plataforma         | Descrição                                                |
|-----------------------------|--------------------|----------------------------------------------------------|
| `cloudsql_proxy.sh`         | Linux / macOS      | Conecta ao Cloud SQL com autenticação via navegador      |
| `setup-gcloud-cloudsql.ps1` | Windows (PowerShell)| Conecta ao Cloud SQL com instalação e autenticação       |

## Requisitos

### Pré-requisitos comuns

- Conta Google com acesso ao projeto GCP
- Projeto GCP e instância PostgreSQL ativos
- SDK do Google Cloud instalado
- Permissão para usar o Cloud SQL Proxy

### macOS / Linux

- `bash`, `curl`, `lsof`
- `brew` instalado (apenas para macOS)
- `sudo` disponível (para instalação em Linux)

### Windows

- PowerShell 5.1 ou superior
- Permissões administrativas para instalação do SDK

## Como usar

### No Linux ou macOS

1. Torne o script executável:

```bash
chmod +x cloudsql_proxy.sh
````

2. Execute o script:

```bash
./cloudsql_proxy.sh
```

3. Siga as instruções interativas:

   * Faça login na conta Google via navegador
   * Informe o nome do projeto GCP
   * Informe a instância no formato `projeto:regiao:instancia`
   * O script instala o `cloud-sql-proxy` se necessário
   * A porta padrão `5432` será usada se estiver livre, ou outra será selecionada

### No Windows

1. Abra o PowerShell como administrador

2. Defina a política de execução:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. Execute o script:

```powershell
.\setup-gcloud-cloudsql.ps1
```

4. Siga as instruções interativas na tela

## Informações de conexão

Após a execução do proxy, use as seguintes configurações para conectar-se ao banco de dados:

* Host: `127.0.0.1`
* Porta: `5432` (ou a porta escolhida)
* Banco: `<nome_banco>`
* Usuário: `<usuario>`
* Senha: `<senha>`

Você pode usar ferramentas como:

* DBeaver
* PgAdmin
* TablePlus
* psql (terminal)

Exemplo de comando no terminal:

```bash
psql -h 127.0.0.1 -U usuario -d nome_banco
```

## Resolução de problemas

* Se a porta 5432 estiver ocupada, uma nova porta alta (acima de 30000) será selecionada automaticamente.
* Se o `gcloud` não estiver instalado, o script informará o link oficial para instalação.
* Apenas contas humanas são aceitas (o script solicita login pelo navegador, se necessário).

## Testado em

| Sistema Operacional | Versões testadas    |
| ------------------- | ------------------- |
| macOS               | Ventura 13.x        |
| Ubuntu              | 20.04, 22.04, 24.04 |
| Windows             | 10 e 11             |
| Cloud SQL Proxy     | v2.16.0             |

## Estrutura do projeto

```text
.
├── cloudsql_proxy.sh         # Script para Linux/macOS
├── setup-gcloud-cloudsql.ps1 # Script para Windows PowerShell
├── README.md                 # Documentação de uso
```

## Contribuições

Sugestões e melhorias são bem-vindas. Para contribuir:

```bash
git clone https://github.com/seu-usuario/cloudsql-proxy-automation.git
```

## Licença

Este projeto está licenciado sob a Licença MIT. Consulte o arquivo `LICENSE` para mais informações.

```

Se desejar, posso agora gerar esse conteúdo formatado como um novo `README.md` pronto para commit no seu repositório GitHub. Deseja isso?
```
