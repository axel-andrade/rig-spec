# rig-spec — Tutorial em Português

> Guia completo para quem nunca usou o rig-spec.
> Do zero até entregar uma feature com qualidade.

---

## O que é o rig-spec?

Quando você usa um agente de IA para programar (Claude, Gemini, ChatGPT, Cursor...), ele tende a:

- Tentar fazer tudo de uma vez e se perder no meio
- Declarar que terminou sem ter testado direito
- Esquecer tudo quando você abre uma nova conversa
- Inventar soluções que contradizem a arquitetura do seu projeto

O **rig-spec** é uma pasta `.rig/` que você adiciona ao seu projeto. Essa pasta dá ao agente tudo que ele precisa: contexto, regras, memória e um processo claro. Resultado: menos alucinação, mais consistência.

---

## Instalação

Roda uma vez na sua máquina. Funciona no Mac e Linux (Windows: WSL ou Git Bash).

```bash
curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash
```

Depois recarregue o terminal:

```bash
source ~/.bashrc   # ou ~/.zshrc se usar zsh
```

Confirme que funcionou:

```bash
rig-spec version
# rig-spec 1.0.0
```

---

## Fluxo completo

O rig-spec segue sempre a mesma sequência:

```
init → overview → shape → plan → run → validate
```

1. **init** — configura o `.rig/` no projeto
2. **overview** — preenche visão e regras de negócio no HARNESS.md
3. **shape** — cria a especificação da feature
4. **plan** — divide a spec em tasks
5. **run** — monta o contexto para o agente executar cada task
6. **validate** — roda os sensores para verificar se passou

---

## Passo a passo

### 1. Inicializar o projeto

Entre na pasta do seu projeto e rode:

```bash
cd meu-projeto
rig-spec init
```

O comando vai:
- Perguntar o que o projeto faz (alimenta as seções Vision e Business Rules do HARNESS.md)
- Detectar a linguagem/framework automaticamente (Node, Python, Next.js...)
- Criar a pasta `.rig/` com todos os arquivos necessários
- Criar os arquivos de entrada para o seu agente (CLAUDE.md, AGENTS.md, .cursorrules...)

**Exemplo de saída:**

```
→ Stack detected: Express
→ Folder structure created
→ feedforward/rules/ filled for Node.js stack (5 files)
→ feedforward/skills/typescript.skill.md created
→ adapters/ created (claude.md, gemini.md, antigravity.md)
→ Agent entry points created: CLAUDE.md AGENTS.md .cursorrules
```

**Projeto já existente?** Use `--retrofit`:

```bash
rig-spec init --retrofit
```

O retrofit escaneia o projeto real em vez de criar stubs genéricos:
- Lê `src/`, `app/` ou `lib/` (2 níveis) e gera `structure.rules.md` com a **árvore real** do projeto
- Detecta TypeScript (arquivos `.ts`) e ajusta as regras de naming
- Detecta onde ficam os testes (co-localizados ou pasta separada)
- Lista os módulos encontrados em `architecture.rules.md`
- Regras de arquitetura, naming, API e testes ficam como `[DRAFT]` para você completar

**Quer forçar um template específico?**

```bash
rig-spec init --template node-api
rig-spec init --template python-api
rig-spec init --template fullstack-nextjs
rig-spec init --template generic
```

---

### 2. Definir visão e regras de negócio

```bash
rig-spec overview
```

Exibe o `.rig/HARNESS.md` em formato limpo: **Project → Vision → Business Rules → Current Focus → Last Session**.

**Abra `.rig/HARNESS.md`** e preencha:
- `## Vision` — o que o produto faz, para quem e qual problema resolve. É o norte do agente.
- `## Business Rules` — regras de domínio não-negociáveis que o agente deve conhecer antes de qualquer implementação.
  - Exemplo: *"Um prontuário só pode ser acessado pelo médico responsável"*
  - Exemplo: *"Doses de medicação devem ser validadas contra o peso do paciente antes de salvar"*

Essas seções foram pré-preenchidas com o que você descreveu no `init`. Revise e expanda.

---

### 3. Ver o que foi criado

Depois do init, sua pasta `.rig/` vai ter essa estrutura:

```
.rig/
├── HARNESS.md                  ← todo agente lê isso primeiro
├── STANDARDS.md                ← índice: onde está cada padrão do projeto
├── feedforward/
│   ├── specs/                  ← onde ficam as specs das features
│   ├── tasks/                  ← onde ficam as tasks
│   ├── rules/                  ← arquitetura, naming, API, UI, testes
│   ├── skills.registry.md      ← roteamento automático de skills por palavra-chave
│   ├── skills/                 ← contexto especializado (TypeScript, FastAPI...)
│   └── mcp.config.md           ← servidores MCP (opcional)
├── feedback/
│   ├── sensors/                ← linters, testes, endpoints, compliance
│   ├── reports/                ← relatórios visuais do validate
│   ├── review/                 ← skills de review (sempre no validate)
│   └── audit/                  ← sensores contínuos de drift
├── memory/
│   ├── progress.md             ← o que foi feito, o que falta
│   ├── decisions.md            ← decisões arquiteturais
│   ├── learnings.md            ← descobertas de implementação e gotchas
│   ├── bootstrap.md            ← ordem de leitura para nova sessão
│   └── research/               ← notas de pesquisa
├── orchestration/
│   ├── implementer.md          ← perfil do agente que implementa
│   ├── validator.md            ← perfil do agente que valida
│   └── contracts/              ← acordos por task
└── adapters/
    ├── claude.md               ← dicas específicas para o Claude
    ├── gemini.md               ← dicas para o Gemini
    └── antigravity.md          ← dicas para o Antigravity
```

---

### 4. Criar uma spec

Uma spec é um documento que define o que vai ser construído antes de qualquer código ser escrito.

```bash
rig-spec shape "sistema de notificações"
```

O comando vai fazer 5 perguntas:

```
1. Qual problema isso resolve?
   → Usuários não sabem quando eventos importantes acontecem

2. Quem são os usuários?
   → Usuários logados na plataforma

3. Qual é o objetivo principal?
   → Notificar em tempo real via WebSocket e por email

4. O que está fora do escopo?
   → Push notifications mobile

5. Alguma restrição ou decisão de design?
   → Usar o servidor WebSocket já existente
```

**O que acontece depois:**

1. Uma spec pré-preenchida é criada em `.rig/feedforward/specs/sistema-de-notificacoes.spec.md`
2. Um arquivo de contexto é gerado em `.rig/context-shape-sistema-de-notificacoes.md`

**Próximos passos:**

1. Abra a spec e preencha a seção **Approved Fixtures** — são os exemplos de entrada/saída esperados que você define. Isso é obrigatório e só você pode fazer.

2. Cole o conteúdo do contexto no seu agente:

```bash
cat .rig/context-shape-sistema-de-notificacoes.md
```

O agente vai completar as User Stories e os Critérios de Aceite com base nas suas respostas.

> **Por que eu preciso preencher os Approved Fixtures?**
> Porque eles definem o que "funcionando corretamente" significa. O agente nunca inventa isso — é você quem decide. Exemplo:
>
> **Input:** usuário A menciona usuário B em um comentário
> **Output esperado:** notificação criada com tipo "mention", email enfileirado em até 5 segundos, badge do B incrementado em 1

---

### 5. Dividir em tasks

Com a spec pronta, quebre em tasks menores:

```bash
rig-spec plan sistema-de-notificacoes
```

Isso monta um contexto em `.rig/context-plan-sistema-de-notificacoes.md`. Cole no seu agente — ele vai criar os arquivos de task em `.rig/feedforward/tasks/sistema-de-notificacoes/`.

Cada task vai ter:
- O que construir
- Onde construir (arquivos específicos)
- Ownership de arquivos (qual task pode tocar qual arquivo)
- Dependências entre tasks
- Contrato — checklist do que significa "pronto"

---

### 6. Executar uma task

```bash
rig-spec run task-01
```

O comando monta o contexto completo em `.rig/context-task-01.md` com:
- **STANDARDS.md** — índice dos padrões
- Visão geral do projeto (HARNESS.md)
- Estado atual (progress.md)
- A spec da feature
- Todas as regras em `feedforward/rules/` (arquitetura, naming, API, tokens de UI…)
- **Skills automáticas** — `skills.registry.md` detecta backend/frontend/testes pelas palavras da task
- Skills explícitas listadas na task
- A task específica e o contrato

**Roteamento de skills:** edite `.rig/feedforward/skills.registry.md` para mapear palavras-chave → skills locais ou externas (`~/.claude/skills/...`). Exemplo: task com "endpoint" e "service" carrega a skill de Node/FastAPI automaticamente.

Cole no agente:

```bash
cat .rig/context-task-01.md
```

O agente lê tudo, implementa o que está no contrato e assina cada item.

> Os arquivos `context-*.md` são temporários e já estão no `.rig/.gitignore` — não vão parar no seu repositório.

**E se o agente não conseguir terminar em uma sessão?**

Tasks longas podem exceder a janela de contexto. Quando isso acontece, o agente deve seguir o **Continuation Protocol**:

1. Escreve um `[CHECKPOINT]` em `memory/progress.md` com o que foi feito e o que falta
2. Deixa os itens de contrato incompletos desmarcados
3. Sinaliza: `CHECKPOINT SAVED — run rig-spec resume to continue`

Você roda `rig-spec resume` — o próximo agente começa com contexto limpo e lê o checkpoint para saber exatamente onde continuar.

---

### 7. Validar

Depois que o agente terminou:

```bash
rig-spec validate
```

Roda todos os sensores configurados em `.rig/feedback/sensors/` e mostra pass/fail para cada um.

Para ver os resultados junto com o contrato de uma task específica:

```bash
rig-spec validate task-01
```

**Artefato visual:** o comando gera `.rig/feedback/reports/validation-task-01-AAAA-MM-DD.md` com:

- Tabela **Sensor matrix** (PASS / FAIL / REVIEW por sensor)
- Checklist do **contrato** da task
- Instruções para o **agente de review** (`code-review.review.md` + `validation-matrix.review.md` + `STANDARDS.md`)

Sensores **inferenciais** (`standards-compliance`, `spec-compliance`) aparecem como `REVIEW` — o CLI não marca PASS sozinho. Rode um agente revisor com o relatório e as regras em `feedforward/rules/`.

**Padrões do projeto:** antes de implementar, o agente deve ler `.rig/STANDARDS.md` e os `*.rules.md` aplicáveis (arquitetura, naming, API, `design-tokens.rules.md` para front).

**Se algum sensor computacional falhar:**

O agente recebe a lista de falhas específicas e corrige. Você roda `rig-spec validate` novamente até tudo passar.

**Quando tudo passar, marque a task como concluída:**

```bash
rig-spec done task-01
```

O comando atualiza o `progress.md`, aponta para a próxima task e — se você estiver em um repositório git com alterações não commitadas — sugere o comando de commit:

```
git add -p
git commit -m "feat(sistema-de-notificacoes): task-01 — [resumo]"
```

A sugestão aparece formatada com o nome da feature e o id da task. O commit é sempre do humano — o agente nunca commita por conta própria.

---

### 8. Retomar uma sessão

Abriu o computador no dia seguinte e não lembra onde parou?

```bash
rig-spec resume
```

Imprime o contexto completo: projeto, o que foi feito, o que está pendente, descobertas de implementação (`learnings.md`) e a spec ativa. Cole no agente e continue de onde parou — sem gastar tokens reconstruindo contexto.

Se a sessão anterior terminou com um `[CHECKPOINT]` em `progress.md`, o agente lê e sabe exatamente onde continuar dentro da task interrompida.

---

### 9. Verificar o status

```bash
rig-spec status
```

Mostra: feature ativa, tasks concluídas, sensores configurados, última sessão.

---

### 10. Auditoria de drift

Com o tempo, o código pode se desviar dos padrões do projeto — não em uma mudança, mas aos poucos. Rode periodicamente:

```bash
rig-spec audit
```

Gera um relatório em `.rig/feedback/audit/report-YYYY-MM-DD.md` com: código morto, dependências desatualizadas, violações de arquitetura.

---

## Como usar com o seu agente de IA

O rig-spec funciona com qualquer ferramenta de IA — mas a forma de usá-lo muda dependendo da ferramenta. Existem dois modos:

---

### Modo 1 — Agentes que leem arquivos (Claude Code, Cursor, Windsurf)

Essas ferramentas leem o projeto diretamente. O `rig-spec init` já criou os arquivos de entrada:

```
CLAUDE.md         ← Claude Code lê isso automaticamente
.cursorrules      ← Cursor lê isso automaticamente
.windsurfrules    ← Windsurf lê isso automaticamente
AGENTS.md         ← genérico para qualquer agente que suporte
```

Todos esses arquivos contêm a mesma instrução:

```
Read .rig/HARNESS.md and .rig/memory/bootstrap.md at the start of every session.
```

**Como usar:**

Você não precisa colar nada. Só abra o projeto e comece a conversar. O agente lê o HARNESS.md automaticamente e já sabe o contexto.

Para uma task específica, rode no terminal:

```bash
rig-spec run task-01
```

Isso gera `.rig/context-task-01.md`. Diga ao agente:

```
Read .rig/context-task-01.md and implement what the contract specifies.
```

O agente lê o arquivo, implementa e assina o contrato. Depois:

```bash
rig-spec validate task-01
```

---

### Modo 2 — Chats (Claude.ai, ChatGPT, Gemini, qualquer chat)

Ferramentas de chat não leem seus arquivos locais — elas não conseguem criar ou editar arquivos no seu computador. **Tudo que o agente "salva" existe só na conversa.** Você precisa copiar o output de volta para os arquivos manualmente.

---

**Para criar uma spec (`shape`):**

```bash
rig-spec shape "nome da feature"
cat .rig/context-shape-nome-da-feature.md
```

Cole no chat. O agente vai responder com um bloco assim:

```
## File: .rig/feedforward/specs/nome-da-feature.spec.md
```markdown
# Spec: nome da feature
...conteúdo completo...
```
```

Você copia esse conteúdo e salva no arquivo mostrado.

---

**Para criar tasks (`plan`):**

```bash
rig-spec plan nome-da-feature
cat .rig/context-plan-nome-da-feature.md
```

Cole no chat. O agente vai responder com um bloco por task:

```
## File: .rig/feedforward/tasks/nome-da-feature/task-01-xxx.task.md
```markdown
# Task 01 — ...
...conteúdo completo...
```

## File: .rig/feedforward/tasks/nome-da-feature/task-02-xxx.task.md
```markdown
# Task 02 — ...
...
```
```

Crie cada arquivo no caminho mostrado e cole o conteúdo.

---

**Para implementar uma task (`run`):**

```bash
rig-spec run task-01
cat .rig/context-task-01.md
```

Cole no chat. O agente implementa e responde com o código. Você copia cada arquivo para o seu projeto.

---

**Para retomar uma sessão:**

```bash
rig-spec resume
```

Copie o output e cole no chat. O agente reconstrói o contexto completo.

---

### Comparação rápida

| Ferramenta | Modo | O que fazer |
|---|---|---|
| Claude Code (CLI/IDE) | Lê arquivos | Abra o projeto. Diga `read .rig/context-task-01.md` |
| Cursor | Lê arquivos | Abra o projeto. `.cursorrules` já configura o contexto |
| Windsurf | Lê arquivos | Abra o projeto. `.windsurfrules` já configura o contexto |
| Claude.ai (chat) | Cola contexto | `rig-spec run task-01` → copie o output → cole no chat |
| ChatGPT (chat) | Cola contexto | `rig-spec run task-01` → copie o output → cole no chat |
| Gemini (chat) | Cola contexto | `rig-spec run task-01` → copie o output → cole no chat |

---

### O que cada comando gera para colar

| Comando | Arquivo gerado | Quando usar |
|---|---|---|
| `rig-spec run task-01` | `.rig/context-task-01.md` | Para implementar uma task |
| `rig-spec shape "feature"` | `.rig/context-shape-[slug].md` | Para criar uma spec |
| `rig-spec plan feature` | `.rig/context-plan-[slug].md` | Para criar tasks a partir de uma spec |
| `rig-spec resume` | (imprime direto) | Para retomar onde parou |

Os arquivos `context-*.md` são temporários e estão no `.rig/.gitignore` — não vão para o repositório.

---

## Os dois caminhos de trabalho

### Caminho 1 — Você orquestra (mais simples)

Você gerencia os passos, colando contextos no seu agente favorito:

```
shape → plan → run → validate → run → validate → ...
```

Cada comando monta um contexto limpo. Você cola no Claude, Gemini, GPT ou qualquer outro.

### Caminho 2 — Dois agentes (mais robusto)

Um agente implementa, outro valida. Eles não podem ser o mesmo — quem faz não julga o próprio trabalho.

```
run  → Implementador: lê contexto, escreve código, assina contrato
     → Validador: lê contrato + código + sensores, aprova ou lista falhas
     → Se falhou: implementador corrige → valida de novo
```

Os perfis estão prontos em:
- `.rig/orchestration/implementer.md`
- `.rig/orchestration/validator.md`

---

## Regras e Skills

### Regras (feedforward/rules/)

São as convenções do seu projeto. O agente lê antes de qualquer task.

| Arquivo | O que define |
|---|---|
| `architecture.rules.md` | Camadas, módulos, o que pode importar o quê |
| `naming.rules.md` | Nomenclatura de arquivos, classes, funções |
| `structure.rules.md` | Onde cada tipo de arquivo deve ficar |
| `api.rules.md` | Formato de resposta, status codes, validação |
| `testing.rules.md` | O que testar, como estruturar os testes |
| `component.rules.md` | Padrões de componentes React (apenas Next.js) |

Se você usou `--retrofit`, esses arquivos têm marcadores `[DRAFT]`. Preencha com os padrões que já existem no seu projeto e remova os `[DRAFT]`.

### Skills (feedforward/skills/)

São arquivos de contexto especializado. Exemplos gerados automaticamente:

- `typescript.skill.md` — padrões de tipagem, o que evitar
- `nodejs.skill.md` — async/await, tratamento de erros, config
- `fastapi.skill.md` — routers, dependency injection, schemas
- `react.skill.md` — componentes, hooks, estado
- `nextjs.skill.md` — App Router, Server Components, Server Actions

Você pode criar skills para qualquer tecnologia ou domínio específico do seu projeto. Copie `_TEMPLATE.skill.md` e preencha.

---

## Padrões do projeto (onde colocar o quê)

| Tipo de informação | Arquivo |
|---|---|
| Índice geral | `.rig/STANDARDS.md` |
| Arquitetura / camadas | `feedforward/rules/architecture.rules.md` |
| Nomes de arquivos e símbolos | `feedforward/rules/naming.rules.md` |
| Pastas e módulos | `feedforward/rules/structure.rules.md` |
| API REST/GraphQL | `feedforward/rules/api.rules.md` |
| Testes | `feedforward/rules/testing.rules.md` |
| Componentes React | `feedforward/rules/component.rules.md` |
| Cores, tipografia, spacing | `feedforward/rules/design-tokens.rules.md` |

No **retrofit**, `structure.rules.md` já nasce preenchido com a árvore real do `src/`. O restante fica `[DRAFT]` até você documentar os padrões reais do time.

Em **cada task**, liste em `## Standards to Follow` quais arquivos de regra se aplicam.

---

## Skills automáticas

Edite `.rig/feedforward/skills.registry.md`:

```markdown
| Domain | Skill path | Match keywords |
| backend | `feedforward/skills/nodejs.skill.md` | service, api, endpoint |
```

Skills externas (instaladas no sistema):

```markdown
| security | `~/.claude/skills/cc-skill-security-review/SKILL.md` | auth, jwt, password |
```

No `rig-spec run`, skills locais e externas (se o arquivo existir) entram no contexto automaticamente.

Para desligar o roteamento em uma task: `skills: manual`

---

## Sensores

Sensores são verificações automáticas que rodam com `rig-spec validate`. Cada arquivo `*.sensor.md` dentro de `.rig/feedback/sensors/` é detectado automaticamente — não há registro manual.

---

### Os dois tipos de sensor

| Tipo | Como funciona | Quando usar |
|---|---|---|
| **Computacional** | Roda um comando shell. Passa se exit code = 0. | Linter, type checker, test runner, cobertura |
| **Inferencial** | O agente lê o código + spec e emite um veredicto. | Conformidade semântica, padrões subjetivos |

A maioria dos seus sensores será computacional. Sensores inferenciais são para o que ferramentas não conseguem checar automaticamente.

---

### O que já vem pronto

**Criados automaticamente pelo `rig-spec init`** (quando a ferramenta é detectada):

| Ferramenta encontrada | Sensor criado |
|---|---|
| ESLint | `lint.sensor.md` |
| TypeScript | `typecheck.sensor.md` |
| `"test"` no package.json | `test.sensor.md` |
| Ruff | `lint.sensor.md` |
| mypy | `typecheck.sensor.md` |
| pytest | `test.sensor.md` |

**Templates prontos, precisam de configuração manual** (em `feedback/sensors/`):

| Arquivo | O que verifica |
|---|---|
| `arch.sensor.md` | Limites de módulos (ex: controller não importa repository diretamente) |
| `naming.sensor.md` | Convenções de nomenclatura de arquivos e classes |
| `spec-compliance.sensor.md` | Agente verifica se o código implementa o que a spec define |
| `standards-compliance.sensor.md` | Agente verifica se o código segue as `rules/` |

---

### Como criar um sensor novo

**Passo 1 — Copie o template:**

```bash
cp .rig/feedback/sensors/_TEMPLATE.sensor.md .rig/feedback/sensors/coverage.sensor.md
```

**Passo 2 — Preencha os campos obrigatórios:**

```markdown
# Sensor: Cobertura de Testes

**Type:** Computational
**Timing:** After every task

## Command
```bash
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'
```

## Pass condition
Exit code 0. Cobertura de linhas ≥ 80% em todos os módulos.

## On failure
Escreva testes para os caminhos não cobertos. Não reduza o threshold.
```

**Passo 3 — Pronto.** O sensor é detectado automaticamente no próximo `rig-spec validate`.

---

### Fluxo para decidir o que sensorisar

```
Existe ferramenta que checa isso automaticamente?
│
├── SIM → Sensor computacional
│         Exemplo: eslint, tsc, pytest, npm test, depcruise
│
└── NÃO → Só humano ou IA consegue julgar?
          │
          ├── IA consegue → Sensor inferencial
          │                 Exemplo: "o código segue o padrão da spec?"
          │
          └── Só humano  → Checklist no contrato da task (não sensor)
```

---

### Exemplos reais de sensores computacionais

**Cobertura mínima (Node.js):**
```markdown
## Command
```bash
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'
```
## Pass condition
Exit code 0.
```

**Limites de arquitetura (depcruise):**
```markdown
## Command
```bash
npx depcruise src/ --config .dependency-cruiser.json
```
## Pass condition
Exit code 0. Zero violações de boundary.
```

**Cobertura mínima (Python):**
```markdown
## Command
```bash
pytest --cov=src --cov-fail-under=80
```
## Pass condition
Exit code 0.
```

**Build sem erros (Next.js):**
```markdown
## Command
```bash
npm run build
```
## Pass condition
Exit code 0. Zero erros de build.
```

---

### Exemplo de sensor inferencial

Sensores inferenciais não têm `## Command` com shell — o agente é o verificador:

```markdown
# Sensor: Conformidade com a Spec

**Type:** Inferential
**Timing:** After every task

## O que verificar

Leia `.rig/feedforward/specs/[feature].spec.md` e o código implementado.
Para cada User Story e Critério de Aceite, confirme se o código os satisfaz.

## Pass condition

Todos os critérios de aceite têm implementação correspondente.
Os Approved Fixtures produzem o output esperado.

## On failure

Liste os critérios não atendidos. O implementador corrige antes de assinar o contrato.
```

---

### Dicas

- **Nomeie com propósito:** `lint.sensor.md`, `typecheck.sensor.md`, `coverage.sensor.md` — o nome aparece no output do validate.
- **Um sensor, uma responsabilidade.** Não junte lint + typecheck em um único sensor — falhas ficam ambíguas.
- **Timing importa.** Sensores lentos (integração, build completo) podem ser marcados como `After integration` para não travar o ciclo de tasks rápidas.
- **Threshold explícito.** Sempre coloque o número mínimo aceitável no `## Pass condition`. "Testes passando" é vago; "≥ 80% de cobertura de linhas" é verificável.
- **On failure claro.** O agente lê esse campo quando o sensor falha. Diga exatamente o que ele deve fazer — e o que ele **não** deve fazer (ex: "não reduza o threshold", "não use `--no-verify`").

---

## Exemplo completo do zero

```bash
# 1. Instalar (uma vez por máquina)
curl -fsSL https://raw.githubusercontent.com/axel-andrade/rig-spec/main/install.sh | bash
source ~/.bashrc

# 2. Entrar no projeto e inicializar
cd meu-projeto
rig-spec init
# → descreva o projeto (alimenta Vision e Business Rules), aguarde detecção de stack

# 3. Revisar visão e regras de negócio
rig-spec overview
# → abre visão do produto e regras de domínio para confirmar/expandir
# → edite .rig/HARNESS.md: seções Vision e Business Rules

# 4. Criar a spec
rig-spec shape "cadastro de usuários"
# → responda as 5 perguntas
# → preencha os Approved Fixtures na spec gerada

# 5. Dividir em tasks
rig-spec plan cadastro-de-usuarios
# → cole o contexto no agente → ele cria as tasks

# 6. Executar task 01
rig-spec run task-01
# → cole o contexto no agente → ele implementa

# 7. Validar
rig-spec validate task-01
# → todos os sensores passaram? marque como done
# → algum falhou? agente corrige → valida de novo

# 8. Marcar task como concluída e commitar
rig-spec done task-01
# → progress.md atualizado → próxima task indicada
# → git add -p && git commit -m "feat(cadastro-de-usuarios): task-01 — [resumo]"

# 9. Próxima task
rig-spec run task-02
rig-spec validate task-02
rig-spec done task-02

# 10. Nova sessão (amanhã)
rig-spec resume
# → cole no agente → contexto completo reconstruído → continue
# → se tinha [CHECKPOINT], agente continua de onde parou

# 11. Ver progresso
rig-spec status
```

---

## Perguntas frequentes

**Precisa instalar Node.js, Python ou qualquer runtime?**
Não. O rig-spec é um script bash puro. Funciona em qualquer Unix sem dependências.

**Funciona com qual agente de IA?**
Com qualquer um. Claude, Gemini, ChatGPT, Cursor, Windsurf, Antigravity. Tudo é Markdown — você cola o contexto onde quiser.

**O `.rig/` deve ir para o git?**
Sim. O `.rig/` é o harness do projeto — faz parte do repositório. Os únicos arquivos ignorados são os `context-*.md` (temporários), que já estão no `.rig/.gitignore`.

**Posso usar em projeto existente?**
Sim. Use `rig-spec init --retrofit`. O comando varre o `src/` real do projeto e gera `structure.rules.md` com a estrutura de pastas encontrada. Arquitetura, naming, API e testes ficam como `[DRAFT]` para você completar com os padrões existentes.

**O agente pode alterar os Approved Fixtures?**
Não. Os fixtures são definidos pelo humano antes dos testes serem escritos. O agente é instruído explicitamente a não tocá-los. Se um teste falha, o código é corrigido — nunca o fixture.

**E se o agente parar no meio de uma task?**
É o comportamento esperado para tasks longas. O agente escreve um `[CHECKPOINT]` em `memory/progress.md` descrevendo o que foi feito e o que falta, deixa os itens do contrato incompletos desmarcados e sinaliza para você rodar `rig-spec resume`. O próximo agente começa com contexto limpo e continua do checkpoint — sem perder trabalho.

**E se eu não quiser usar dois agentes?**
Tudo bem. O Caminho 1 (agente único, você valida) funciona perfeitamente. Os perfis de implementer/validator ficam disponíveis quando você estiver pronto para o Caminho 2.

---

## Referência rápida dos comandos

| Comando | O que faz |
|---|---|
| `rig-spec init` | Inicializa `.rig/` detectando stack automaticamente |
| `rig-spec init --retrofit` | Modo projeto existente — escaneia `src/`, gera structure.rules real, demais como [DRAFT] |
| `rig-spec init --template <nome>` | Força template: `node-api`, `python-api`, `fullstack-nextjs`, `generic` |
| `rig-spec overview` | Exibe visão do produto, regras de negócio e estado atual em tela limpa |
| `rig-spec shape "feature"` | Faz 5 perguntas, cria spec, monta contexto para o agente completar |
| `rig-spec plan <spec>` | Monta contexto para o agente criar as tasks |
| `rig-spec run <task-id>` | Monta contexto completo para o agente implementar |
| `rig-spec validate` | Roda sensores + gera relatório em `feedback/reports/` |
| `rig-spec validate <task-id>` | Sensores + contrato + relatório com matriz de validação |
| `rig-spec done <task-id>` | Marca task como concluída, atualiza progress.md, sugere commit git |
| `rig-spec resume` | Imprime contexto completo para retomar sessão (inclui learnings e checkpoint) |
| `rig-spec status` | Mostra progresso: feature ativa, tasks, última sessão |
| `rig-spec research <tema>` | Cria arquivo de pesquisa em `memory/research/` |
| `rig-spec audit` | Roda sensores de drift, salva relatório |
| `rig-spec version` | Mostra versão instalada |
