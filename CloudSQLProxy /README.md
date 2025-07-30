# Cloud SQL Proxy - Scripts de Conexão Automática

Este repositório contém dois scripts automatizados para conexão segura com o Cloud SQL (PostgreSQL) do Google Cloud. Eles são compatíveis com sistemas macOS, Linux e Windows, com autenticação humana via navegador e verificação automática de porta.

## Autor

George Rodrigues de Oliveira  
GitHub: [github.com/georgeroliveira](https://github.com/georgeroliveira)  
Licença: MIT

---

## O que os scripts fazem

### `cloudsql_proxy.sh` (Linux/macOS)

Este script automatiza a configuração de uma conexão segura entre sua máquina local e uma instância do Cloud SQL (PostgreSQL) do Google Cloud, usando o `cloud-sql-proxy`.

**Etapas realizadas:**

1. Detecta o sistema operacional (Linux ou macOS).
2. Verifica e instala dependências essenciais como `curl`, `lsof` e `brew` (no macOS).
3. Garante que o SDK do Google Cloud (`gcloud`) está instalado.
4. Verifica se há login humano ativo no `gcloud` e força o login se necessário.
5. Solicita o nome do projeto GCP e configura como projeto ativo.
6. Solicita a instância do Cloud SQL no formato `projeto:regiao:instancia`.
7. Verifica se a porta 5432 está em uso e, se necessário, escolhe outra porta automaticamente.
8. Baixa e instala o `cloud-sql-proxy` se não estiver presente.
9. Inicia o proxy local para permitir a conexão ao banco de dados remoto via `localhost`.
10. Exibe as instruções de conexão para ferramentas como `psql`, DBeaver e PgAdmin.

---

### `setup-gcloud-cloudsql.ps1` (Windows PowerShell)

Este script realiza o mesmo processo que o `cloudsql_proxy.sh`, mas adaptado ao ambiente Windows com PowerShell.

**Etapas realizadas:**

1. Verifica permissões e política de execução no PowerShell.
2. Instala o SDK do Google Cloud caso esteja ausente.
3. Solicita login com conta humana via navegador.
4. Solicita o nome do projeto GCP e a instância Cloud SQL.
5. Verifica se a porta 5432 está em uso e escolhe automaticamente uma porta alternativa, se necessário.
6. Baixa e instala o `cloud-sql-proxy` para Windows.
7. Inicia o proxy e exibe informações de conexão.

---

## Scripts Disponíveis

| Arquivo                      | Plataforma          | Descrição                                                |
|-----------------------------|---------------------|----------------------------------------------------------|
| `cloudsql_proxy.sh`         | Linux / macOS       | Conecta ao Cloud SQL com autenticação via navegador      |
| `setup-gcloud-cloudsql.ps1` | Windows (PowerShell) | Conecta ao Cloud SQL com instalação e autenticação       |

---

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

---

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

---

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

---

## Informações de conexão

Após a execução do proxy, use as seguintes configurações para conectar-se ao banco de dados:

* Host: `127.0.0.1`
* Porta: `5432` (ou a porta escolhida)
* Banco: `<nome_banco>`
* Usuário: `<usuario>`
* Senha: `<senha>`

Ferramentas compatíveis:

* DBeaver
* PgAdmin
* TablePlus
* psql (linha de comando)

Exemplo de uso com psql:

```bash
psql -h 127.0.0.1 -U usuario -d nome_banco
```

---

## Resolução de problemas

* Se a porta 5432 estiver ocupada, o script seleciona automaticamente uma porta alta livre (entre 30000 e 39999).
* Se o `gcloud` não estiver instalado, será exibido o link oficial para instalação.
* O script exige login humano. Contas de serviço ou contas `compute@` não são aceitas.

---

## Testado em

| Sistema Operacional | Versões testadas    |
| ------------------- | ------------------- |
| macOS               | Ventura 13.x        |
| Ubuntu              | 20.04, 22.04, 24.04 |
| Windows             | 10 e 11             |
| Cloud SQL Proxy     | v2.16.0             |

---

## Estrutura do projeto

```text
.
├── cloudsql_proxy.sh          # Script para Linux/macOS
├── setup-gcloud-cloudsql.ps1  # Script para Windows PowerShell
├── README.md                  # Documentação de uso
```

---

## Contribuições

Sugestões e melhorias são bem-vindas. Para contribuir:

```bash
git clone https://github.com/seu-usuario/cloudsql-proxy-automation.git
```

---

## Licença

Este projeto está licenciado sob a Licença MIT. Consulte o arquivo `LICENSE` para mais informações.

```

---

Deseja que eu salve este conteúdo como um novo `README.md` para commit direto no seu repositório? Posso gerar o arquivo agora mesmo.
```
