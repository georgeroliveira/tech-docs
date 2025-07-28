# Matomo com Docker Compose

Este repositório fornece um ambiente completo para executar o [Matomo](https://matomo.org/), uma poderosa plataforma de análise web, utilizando Docker Compose com banco de dados MariaDB.

## Serviços

- **Matomo** – Plataforma de analytics open source
- **MariaDB** – Banco de dados para armazenamento dos dados do Matomo
- **Volumes** – Persistência de dados para banco e aplicação

## Requisitos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose v2+](https://docs.docker.com/compose/install/)

## Estrutura

```bash
matomo-docker/
├── docker-compose.yml
└── README.md
```

## Instruções de uso

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/matomo-docker.git
cd matomo-docker
```

### 2. Inicie os serviços

```bash
docker compose up -d
```

### 3. Acesse o Matomo

Abra o navegador e acesse: [http://localhost:8080](http://localhost:8080)

## Configuração via Navegador

Siga os passos no instalador do Matomo:

1. Clique em **"Next"** na tela de boas-vindas
2. Confirme os pré-requisitos do sistema
3. Preencha os dados do banco:

```
Database Server: db
Login: matomo
Password: matomo_pass
Database Name: matomo
Table Prefix: matomo_
```

4. Crie o usuário administrador
5. Configure o site que será monitorado
6. Copie o código de rastreamento fornecido

## Variáveis de Ambiente

Você pode usar um arquivo `.env` com as seguintes variáveis:

```env
MYSQL_DATABASE=matomo
MYSQL_USER=matomo
MYSQL_PASSWORD=matomo_pass
MYSQL_ROOT_PASSWORD=root_pass
```

E modificar o `docker-compose.yml` para usá-las com `${VARIAVEL}`.

## Volumes de dados

- `db_data` → Banco de dados MariaDB
- `matomo_data` → Arquivos persistentes do Matomo

## Backup manual

### Backup do banco de dados
```bash
docker run --rm -v matomo-docker_db_data:/volume -v $(pwd):/backup alpine \
  tar czf /backup/db_backup.tar.gz -C /volume .
```

### Backup dos arquivos do Matomo
```bash
docker run --rm -v matomo-docker_matomo_data:/volume -v $(pwd):/backup alpine \
  tar czf /backup/matomo_backup.tar.gz -C /volume .
```

## Gerenciar os serviços

```bash
# Pausar os containers
docker compose stop

# Iniciar containers parados
docker compose start

# Remover containers (mantém volumes)
docker compose down

# Remover containers e volumes
docker compose down -v
```

## (Opcional) Usar com domínio e HTTPS

Para ambiente de produção com HTTPS, considere:

- Nginx ou Traefik como proxy reverso
- Certbot ou Let's Encrypt para SSL
- Docker secrets para variáveis sensíveis

Posso ajudar a configurar isso se necessário.

## Troubleshooting

### Problemas comuns

**Container não inicia:**
```bash
docker compose logs matomo
docker compose logs db
```

**Resetar completamente:**
```bash
docker compose down -v
docker compose up -d
```

**Verificar status dos containers:**
```bash
docker compose ps
```

## Referências

- [Documentação oficial do Matomo](https://matomo.org/docs/)
- [Imagem oficial no Docker Hub](https://hub.docker.com/_/matomo)
- [Docker Compose](https://docs.docker.com/compose/)

## Licença

MIT © [Seu Nome ou Organização]
