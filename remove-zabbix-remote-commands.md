# Remoção de Diretivas Perigosas no Zabbix Agent via Ansible

## Objetivo

Este procedimento remove ou comenta as diretivas `AllowKey=system.run[*]` e `LogRemoteCommands=1` do arquivo de configuração do Zabbix Agent (`zabbix_agentd.conf`) em múltiplos hosts, reforçando a segurança do ambiente.

---

## Arquivo: `remover_diretivas_perigosas_zabbix.yml`

```yaml
---
- name: Remover ou comentar diretivas perigosas do Zabbix Agent
  hosts: all
  become: yes
  vars:
    config_file: "/etc/zabbix/zabbix_agentd.conf"
    modo_remocao: "comentar"  # opções: "comentar" ou "remover"

  tasks:

    - name: Garantir que o arquivo de configuração existe
      stat:
        path: "{{ config_file }}"
      register: conf_check

    - name: Abortar se o arquivo não existir
      fail:
        msg: "Arquivo {{ config_file }} não encontrado."
      when: not conf_check.stat.exists

    - name: Comentar diretiva AllowKey
      lineinfile:
        path: "{{ config_file }}"
        regexp: '^AllowKey=system\.run\[\*\]'
        line: "# AllowKey=system.run[*]"
        state: present
      when: modo_remocao == 'comentar'

    - name: Comentar diretiva LogRemoteCommands
      lineinfile:
        path: "{{ config_file }}"
        regexp: '^LogRemoteCommands='
        line: "# LogRemoteCommands=1"
        state: present
      when: modo_remocao == 'comentar'

    - name: Remover diretiva AllowKey (modo remover)
      lineinfile:
        path: "{{ config_file }}"
        regexp: '^AllowKey=system\.run\[\*\]'
        state: absent
      when: modo_remocao == 'remover'

    - name: Remover diretiva LogRemoteCommands (modo remover)
      lineinfile:
        path: "{{ config_file }}"
        regexp: '^LogRemoteCommands='
        state: absent
      when: modo_remocao == 'remover'

    - name: Reiniciar o serviço do Zabbix Agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: yes
```

---

## Execução

1. Ajuste o inventário com os hosts alvo:

Exemplo: `inventory.ini`

```ini
[zabbix_agents]
192.168.10.101
192.168.10.102
```

2. Comentar as diretivas (modo seguro):

```bash
ansible-playbook -i inventory.ini remover_diretivas_perigosas_zabbix.yml -e modo_remocao=comentar
```

3. Remover completamente as diretivas (modo estrito):

```bash
ansible-playbook -i inventory.ini remover_diretivas_perigosas_zabbix.yml -e modo_remocao=remover
```

---

## Resultado Esperado

- As diretivas críticas `AllowKey=system.run[*]` e `LogRemoteCommands=1` não estarão mais ativas.
- O serviço `zabbix-agent` será reiniciado para aplicar as mudanças.
- A execução remota via Zabbix será desabilitada.

---

## Observações

- O playbook é idempotente e seguro para execuções repetidas.
- Compatível com Ubuntu 18.04, 20.04, 22.04 e 24.04.
