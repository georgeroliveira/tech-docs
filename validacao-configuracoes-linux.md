# Documentação de Validação de Configurações Críticas no Linux

##  Objetivo

Garantir que alterações em arquivos sensíveis como `sudoers` e `sshd_config` sejam **validadas corretamente antes de aplicar**, evitando erros que possam causar perda de acesso remoto ou de permissões administrativas.

---

##  Validação do arquivo `sshd_config` (configuração SSH)

###  Comando principal:

```bash
sudo sshd -t
```

###  Significado:
- **Sem saída**: Arquivo está OK.
- **Com mensagem de erro**: Há erro de sintaxe ou diretiva incorreta.

---

###  Outras opções úteis:

```bash
sudo sshd -T
```
> Exibe a configuração efetiva completa, incluindo valores padrão.

```bash
sudo sshd -t -f /caminho/personalizado/sshd_config
```
> Valida um arquivo alternativo de configuração SSH.

---

##  Validação do arquivo `sudoers` e seus complementos

###  Comando principal:

```bash
sudo visudo -c
```

###  Significado:
- Verifica `/etc/sudoers` **e todos os arquivos dentro de `/etc/sudoers.d/`**
- Saída esperada:
  ```bash
  /etc/sudoers: parsed OK
  /etc/sudoers.d/admin: parsed OK
  ```

---

###  Para validar um único arquivo de forma isolada:

```bash
sudo visudo -c -f /etc/sudoers.d/admin
```

> Útil ao testar arquivos individuais antes de aplicar.

---

##  Boas práticas

| Arquivo              | Ferramenta recomendada | Motivo                                |
|----------------------|------------------------|----------------------------------------|
| `/etc/sudoers`       | `visudo`               | Validação de sintaxe e segurança       |
| `/etc/sudoers.d/*`   | `visudo -f`            | Edição segura com validação            |
| `/etc/ssh/sshd_config`| `sshd -t`              | Verifica erros antes de reiniciar SSH  |

---

##  Recomendações

- **Nunca edite diretamente `/etc/sudoers` com `vim`, `nano` ou `echo`.**
- Use sempre `visudo` para prevenir travamento de acesso.
- Antes de reiniciar o `sshd`, valide com `sshd -t` para não perder acesso remoto.
- Para acesso remoto via SSH, sempre teste com uma **segunda conexão** antes de aplicar reinício.

---

**Autor:** George Oliveira  
**Atualizado em:** 2025-07-26  
**Licença:** MIT  
