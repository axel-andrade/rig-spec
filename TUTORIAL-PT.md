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
init → shape → plan → run → validate
```

1. **init** — configura o `.rig/` no projeto
2. **shape** — cria a especificação da feature
3. **plan** — divide a spec em tasks
4. **run** — monta o contexto para o agente executar cada task
5. **validate** — roda os sensores para verificar se passou

---

## Passo a passo

### 1. Inicializar o projeto

Entre na pasta do seu projeto e rode:

```bash
cd meu-projeto
rig-spec init
```

O comando vai:
- Perguntar uma descrição do projeto (1 frase)
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

Isso gera as regras como rascunho `[DRAFT]` para você preencher com os padrões que já existem no projeto.

**Quer forçar um template específico?**

```bash
rig-spec init --template node-api
rig-spec init --template python-api
rig-spec init --template fullstack-nextjs
rig-spec init --template generic
```

---

### 2. Ver o que foi criado

Depois do init, sua pasta `.rig/` vai ter essa estrutura:

```
.rig/
├── HARNESS.md                  ← todo agente lê isso primeiro
├── feedforward/
│   ├── specs/                  ← onde ficam as specs das features
│   ├── tasks/                  ← onde ficam as tasks
│   ├── rules/                  ← regras de arquitetura, naming, API, testes
│   ├── skills/                 ← contexto especializado (TypeScript, FastAPI...)
│   └── mcp.config.md           ← servidores MCP (opcional)
├── feedback/
│   ├── sensors/                ← linters, testes, typecheckers
│   ├── review/                 ← instruções para o agente revisor
│   └── audit/                  ← sensores contínuos de drift
├── memory/
│   ├── progress.md             ← o que foi feito, o que falta
│   ├── decisions.md            ← decisões arquiteturais
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

**Abra `.rig/HARNESS.md`** e confirme que as informações do projeto estão corretas. Esse é o arquivo mais importante — todo agente começa por ele.

---

### 3. Criar uma spec

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

### 4. Dividir em tasks

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

### 5. Executar uma task

```bash
rig-spec run task-01
```

O comando monta o contexto completo em `.rig/context-task-01.md` com:
- Visão geral do projeto (HARNESS.md)
- Estado atual (progress.md)
- A spec da feature
- A task específica
- As regras do projeto (rules/)
- As skills relevantes

Cole no agente:

```bash
cat .rig/context-task-01.md
```

O agente lê tudo, implementa o que está no contrato e assina cada item.

> Os arquivos `context-*.md` são temporários e já estão no `.rig/.gitignore` — não vão parar no seu repositório.

---

### 6. Validar

Depois que o agente terminou:

```bash
rig-spec validate
```

Roda todos os sensores configurados em `.rig/feedback/sensors/` e mostra pass/fail para cada um.

Para ver os resultados junto com o contrato de uma task específica:

```bash
rig-spec validate task-01
```

**Se algum sensor falhar:**

O agente recebe a lista de falhas específicas e corrige. Você roda `rig-spec validate` novamente até tudo passar.

---

### 7. Retomar uma sessão

Abriu o computador no dia seguinte e não lembra onde parou?

```bash
rig-spec resume
```

Imprime o contexto completo: projeto, o que foi feito, o que está pendente, próxima task. Cole no agente e continue de onde parou — sem gastar tokens reconstruindo contexto.

---

### 8. Verificar o status

```bash
rig-spec status
```

Mostra: feature ativa, tasks concluídas, sensores configurados, última sessão.

---

### 9. Auditoria de drift

Com o tempo, o código pode se desviar dos padrões do projeto — não em uma mudança, mas aos poucos. Rode periodicamente:

```bash
rig-spec audit
```

Gera um relatório em `.rig/feedback/audit/report-YYYY-MM-DD.md` com: código morto, dependências desatualizadas, violações de arquitetura.

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
# → descreva o projeto, aguarde detecção de stack

# 3. Criar a spec
rig-spec shape "cadastro de usuários"
# → responda as 5 perguntas
# → preencha os Approved Fixtures na spec gerada

# 4. Dividir em tasks
rig-spec plan cadastro-de-usuarios
# → cole o contexto no agente → ele cria as tasks

# 5. Executar task 01
rig-spec run task-01
# → cole o contexto no agente → ele implementa

# 6. Validar
rig-spec validate task-01
# → todos os sensores passaram? próxima task
# → algum falhou? agente corrige → valida de novo

# 7. Próxima task
rig-spec run task-02
rig-spec validate task-02

# 8. Nova sessão (amanhã)
rig-spec resume
# → cole no agente → contexto completo reconstruído → continue

# 9. Ver progresso
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
Sim. Use `rig-spec init --retrofit`. As regras são geradas como `[DRAFT]` para você preencher com os padrões que já existem no projeto.

**O agente pode alterar os Approved Fixtures?**
Não. Os fixtures são definidos pelo humano antes dos testes serem escritos. O agente é instruído explicitamente a não tocá-los. Se um teste falha, o código é corrigido — nunca o fixture.

**E se eu não quiser usar dois agentes?**
Tudo bem. O Caminho 1 (agente único, você valida) funciona perfeitamente. Os perfis de implementer/validator ficam disponíveis quando você estiver pronto para o Caminho 2.

---

## Referência rápida dos comandos

| Comando | O que faz |
|---|---|
| `rig-spec init` | Inicializa `.rig/` detectando stack automaticamente |
| `rig-spec init --retrofit` | Modo projeto existente (regras como [DRAFT]) |
| `rig-spec init --template <nome>` | Força template: `node-api`, `python-api`, `fullstack-nextjs`, `generic` |
| `rig-spec shape "feature"` | Faz 5 perguntas, cria spec, monta contexto para o agente completar |
| `rig-spec plan <spec>` | Monta contexto para o agente criar as tasks |
| `rig-spec run <task-id>` | Monta contexto completo para o agente implementar |
| `rig-spec validate` | Roda todos os sensores |
| `rig-spec validate <task-id>` | Sensores + mostra checklist do contrato da task |
| `rig-spec resume` | Imprime contexto completo para retomar sessão |
| `rig-spec status` | Mostra progresso: feature ativa, tasks, última sessão |
| `rig-spec research <tema>` | Cria arquivo de pesquisa em `memory/research/` |
| `rig-spec audit` | Roda sensores de drift, salva relatório |
| `rig-spec version` | Mostra versão instalada |
