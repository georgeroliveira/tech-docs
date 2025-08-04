
#  Riscos do Uso do ChatGPT em Ambientes Sensíveis

Este documento apresenta os riscos técnicos e institucionais associados ao uso do ChatGPT, especialmente em contextos de infraestrutura crítica, dados públicos, contratos governamentais, DevOps e segurança da informação.

---

##  1. Retenção Temporária de Dados

Mesmo com o histórico desativado, a OpenAI **pode armazenar suas conversas por até 30 dias** para fins de auditoria e análise de abusos.

- **Risco:** Exposição temporária de dados sensíveis a ataques internos, requisições judiciais ou violações acidentais.

---

##  2. Leitura Manual por Auditores

A OpenAI declara que funcionários autorizados **podem revisar conversas manualmente**, mesmo sem salvamento histórico, em casos de:

- Investigações
- Monitoramento de segurança
- Avaliações de qualidade

- **Risco:** Informações confidenciais podem ser visualizadas por terceiros autorizados.

---

##  3. Uso para Treinamento (com histórico ativado)

Se o histórico de chat estiver ativado, **suas conversas são usadas para treinar novos modelos**.

- Isso inclui código-fonte, prompts, cláusulas contratuais, scripts e dados institucionais.

---

##  4. Jurisdição Internacional (EUA)

A OpenAI está sediada nos Estados Unidos e está sujeita ao **Cloud Act** e outras legislações que permitem acesso governamental aos dados.

- **Risco legal:** Conflito com a LGPD e normas internas de segurança em órgãos públicos ou contratos sensíveis.

---

##  5. Ausência de Criptografia de Ponta a Ponta

As conversas são criptografadas em trânsito (HTTPS), mas **não são armazenadas com criptografia de ponta a ponta**.

- **Risco:** A OpenAI tem acesso técnico completo ao conteúdo.

---

## 6. Uso Descuidado por Equipes

O uso inconsciente por colaboradores pode incluir:

- Colagem de senhas, tokens, logs, IPs internos e dados reais

- **Risco organizacional:** Vazamento acidental por uso indevido ou negligente.

---

##  Boas Práticas Recomendadas

-  **Nunca envie dados sensíveis, senhas, contratos reais ou evidências jurídicas**
-  **Desative o histórico e a opção de treino automático**
-  **Use alternativas como o [Lumo (Proton)](https://lumo.proton.me/u/0/) para dados sigilosos**
-  **Implemente guidelines internos de uso seguro de IA**

---

##  Referências

- [OpenAI - Data Usage Policy](https://openai.com/policies/privacy-policy)
- [Cloud Act - US DOJ](https://www.justice.gov/cloudact)
- [LGPD - Brasil](https://www.gov.br/esporte/pt-br/acesso-a-informacao/lgpd)

---

**Autor:** George Oliveira  
**Última atualização:** 2025-08-04  
