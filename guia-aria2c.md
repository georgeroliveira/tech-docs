# Guia Rápido: Instalando e Usando o aria2c no Ubuntu

## 1. O que é o aria2c?

O `aria2c` é um gerenciador de downloads leve e poderoso, capaz de baixar arquivos via HTTP, HTTPS, FTP, SFTP, BitTorrent e Metalink. Ele suporta downloads múltiplos, segmentados e em paralelo.

---

## 2. Instalação no Ubuntu

Abra o terminal e execute:

```bash
sudo apt update
sudo apt install aria2
```

Após a instalação, verifique se está tudo certo:

```bash
aria2c --version
```

---

## 3. Como Usar o aria2c

### 3.1. Download simples (HTTP/HTTPS)

```bash
aria2c https://exemplo.com/arquivo.zip
```

### 3.2. Download múltiplo (vários arquivos de uma vez)

```bash
aria2c https://exemplo.com/arquivo1.zip https://exemplo.com/arquivo2.zip
```

### 3.3. Baixar com várias conexões (mais rápido)

```bash
aria2c -x 16 https://exemplo.com/arquivo.zip
```

O parâmetro `-x 16` define até 16 conexões paralelas.

### 3.4. Baixar via torrent

```bash
aria2c arquivo.torrent
```

Ou usando um link magnet:

```bash
aria2c 'magnet:?xt=urn:btih:...'
```

### 3.5. Baixar arquivos listados em um arquivo de texto

Crie um arquivo chamado `links.txt` com uma lista de URLs (uma por linha) e execute:

```bash
aria2c -i links.txt
```

### 3.6. Retomar download interrompido

Se o download foi pausado ou caiu a conexão, basta rodar o mesmo comando novamente. O `aria2c` tentará continuar de onde parou.

---

## 4. Outras Opções Úteis

### Limitar velocidade de download

```bash
aria2c --max-download-limit=500K https://exemplo.com/arquivo.zip
```

### Definir diretório de destino

```bash
aria2c -d /caminho/do/destino https://exemplo.com/arquivo.zip
```

### Baixar usando autenticação

```bash
aria2c --http-user=USUARIO --http-passwd=SENHA https://exemplo.com/arquivo.zip
```

---

## 5. Ajuda e Documentação

Para ver todas as opções do `aria2c`, rode:

```bash
aria2c --help
```

Ou consulte a documentação oficial:  
https://aria2.github.io/manual/en/html/
