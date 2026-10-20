# Relatórios mensais e vínculo do vendedor — design

Data: 2026-10-20

## Intenção

Hoje o único lugar com números de venda é o dashboard inicial (`Dashboard::OverviewQuery`), que mostra só o mês corrente contra o anterior. Não há como consultar meses passados nem ver percentuais históricos.

O dono e os vendedores querem:

- ver quanto foi vendido em qualquer mês passado;
- comparar esse mês com o mês atual e com os outros meses do ano;
- saber se o percentual de vendas está subindo ou caindo mês a mês;
- saber quais produtos venderam mais e em que quantidade, para decidir compras e avaliar novas culturas/produtos;
- saber quem vendeu.

"Quem vendeu" hoje é o campo de texto livre `sales.responsible_name`, opcional e ausente do formulário. O usuário decidiu que a venda passa a registrar o usuário do sistema que a fez.

## Escopo: duas partes, nesta ordem

1. **Vínculo do vendedor:** a venda registra o usuário que a criou.
2. **Aba Relatórios:** página nova com filtros e indicadores mês a mês.

A parte 2 depende da 1 apenas no filtro e na tabela de vendedores. O resto funciona sem ela.

## Objetivos

- Página "Relatórios" com escolha de mês e comparação percentual e quantitativa.
- Filtros por mês, produto e vendedor.
- Toda venda concluída aparece nos totais, inclusive vendas antigas e importadas sem vendedor vinculado.

## Não objetivos

- Exportar relatório (PDF, planilha).
- Unidade de medida no produto.
- Metas, previsões, comparação com o mesmo mês do ano anterior.
- Alterar o dashboard inicial.
- Mudar quem pode criar ou editar vendas.

## Anti-objetivos (falha mesmo funcionando)

- Venda concluída que some dos totais por não ter vendedor vinculado.
- Viewer acessando os relatórios.
- Números da aba divergindo do dashboard para o mês atual sem filtros. A receita tem que ser igual à do dashboard. Concluídas + pendentes + canceladas têm que somar o "Vendas do mês" do dashboard, que conta todos os status.
- Vendedor mudando quando a venda é editada por outra pessoa.
- Venda perdendo o nome de quem vendeu quando o usuário exclui a conta.

## Restrições

- Rails 8, views em Phlex + RubyUI, Tailwind, Stimulus, importmap, SQLite.
- Sem biblioteca de gráficos instalada.
- Autorização via ActionPolicy (`ApplicationPolicy#can_manage?` = owner, admin, manager).
- Testes em RSpec (`spec/models`, `spec/policies`, `spec/queries`, `spec/requests`, `spec/services`).
- Textos da interface em português.

---

## Parte 1 — Vínculo do vendedor

### Decidido pelo usuário

- O campo "Responsável" passa a ser o usuário do sistema que fez a venda.
- Na criação pelo formulário, o responsável é **sempre quem está logado**. Não há campo para escolher ou trocar.
- Importação por planilha (coluna `RESPONSAVEL`):
  - nome corresponde a um usuário do sistema: venda vinculada a ele;
  - nome não corresponde: venda guarda e exibe o nome em texto, como veio da planilha;
  - coluna vazia: venda aparece como **"Não vinculado"**.
- Nenhuma venda deixa de aparecer nos registros e relatórios.
- Quando um usuário exclui a própria conta (`UsersController#destroy`), as vendas dele perdem o vínculo, mas o `username` é copiado para `responsible_name`. O nome continua aparecendo, agora como texto.

### Modelo de dados (decisão minha)

- Nova coluna `sales.seller_id` (FK para `users`, nula permitida, com índice). Associação `belongs_to :seller, class_name: "User", optional: true`.
- `sales.responsible_name` permanece como texto. Uso: nome vindo da importação quando não há vínculo, vendas antigas e vendas de usuários que excluíram a conta.
- Validação: se `seller` presente, ele precisa ter membership na organização da venda. A checagem só roda na criação ou quando `seller_id` muda, para uma venda antiga continuar editável se o vendedor sair da organização.

### Exclusão de conta (decisão do usuário; mecanismo é decisão minha)

- `User` ganha a associação inversa (ex.: `has_many :sold_sales, class_name: "Sale", foreign_key: :seller_id`).
- Antes de excluir o usuário, na mesma transação: `seller_id = nil` e `responsible_name = username` em todas as vendas dele, de todas as organizações. Isso sobrescreve o texto importado quando havia, o que não muda nada na prática, porque o texto importado já correspondia ao `username` pela regra de vínculo.
- A FK não pode impedir a exclusão: o SQLite do projeto aplica foreign keys.
- Hoje não existe tela para remover um membro da organização. Se um dia existir, o vínculo continua e o nome segue aparecendo.
- Nome exibido do vendedor, em ordem: `seller.username` → `responsible_name` → "Não vinculado". Centralizar num método (ex.: `Sale#seller_display_name`).

### Formulário de venda (decisão minha)

- `SalesController#create` define `seller = Current.user`. `responsible_name` não é mais aceito pelos params do formulário (remover de `sale_params`).
- `update` não altera `seller_id` nem `responsible_name`. O vendedor original fica.
- A tela de nova venda mostra, só leitura, "Responsável: <username de quem está logado>". A edição mostra o vendedor registrado.
- Listagem e detalhe de vendas (`Views::Sales::Index`, `Views::Sales::Show`) passam a usar o nome exibido acima.

### Importação (decisão minha)

- Comparação de `RESPONSAVEL` com `username` dos usuários **que têm membership na organização**, normalizando os dois lados com o mesmo critério de `normalize_text` do importador (transliteração, `strip`, `squeeze`, `upcase`).
- Exatamente um usuário corresponde: preenche `seller_id`. Nenhum ou mais de um: `seller_id` nulo, nome guardado em `responsible_name`.
- `responsible_name` continua sendo gravado mesmo quando há vínculo (guarda o que veio da planilha).

### Vendas existentes (decisão minha)

- Uma migração de dados (ou rake task) aplica a mesma regra de correspondência às vendas que já têm `responsible_name`. Sem correspondência única, nada muda.
- Vendas antigas criadas pelo formulário sem responsável continuam como "Não vinculado". Não há como saber quem as criou.

---

## Parte 2 — Aba Relatórios

### Decidido pelo usuário

- Layout: **página única, tudo empilhado** (modelo A do rascunho).
- Acesso: owner, admin e manager. Viewer não vê o link e não acessa a página.
- O usuário escolhe o mês que quer ver.
- Comparativo contra o mês atual e entre os meses do ano, em % e em quantidade.
- Ranking de produtos com quantidade vendida de cada um.
- Indicadores, produtos, vendedores e gráfico do ano contam **somente vendas concluídas**. Pendentes e canceladas aparecem num bloco separado, com quantidade, valor e percentual.
- A tabela de produtos mostra **todos os produtos já vendidos**, não só os vendidos no mês escolhido, para revelar o que deixou de vender.
- O card de quantidade de vendas se chama **"Vendas concluídas"**, para não confundir com o "Vendas do mês" do dashboard, que conta todos os status. O dashboard não muda.
- Toda comparação que envolve o mês atual usa **os mesmos dias** dos dois lados (ver seção abaixo).

### Comparações com o mês atual: mesmos dias (decisão do usuário)

O mês atual está incompleto. Comparar ele com um mês fechado mostraria queda quase sempre. Regra:

- Seja `d` o dia de hoje (`Date.current.day`, fuso `America/Fortaleza` já configurado no app).
- Quando um dos dois lados de uma comparação é o mês atual, os **dois** lados usam só os dias 1 a `d`. Exemplo, em 20/10: setembro de 1 a 20 contra outubro de 1 a 20.
- Se o outro mês tem menos dias que `d` (ex.: fevereiro com `d` = 30), ele entra inteiro.
- Comparações entre dois meses fechados usam os meses inteiros.
- A regra vale para tudo que tem percentual: cards, variação nas tabelas de produtos e vendedores, e o percentual sobre a barra do mês atual no gráfico do ano.
- Os **valores** exibidos (o número grande do card, as colunas de quantidade e receita, a altura das barras) são sempre do mês inteiro. Só o percentual usa o recorte. Decisão minha, para a receita do mês atual bater com o dashboard.
- O texto da comparação mostra o recorte, ex.: "vs 1 a 20/out". O formato exato fica com o builder.
- Decisão minha: venda com data futura dentro do mês atual entra no valor do mês, mas fica fora do percentual até a data chegar. É raro e não justifica outra regra.

### Navegação e acesso

- Item "Relatórios" no menu lateral (`Views::Layouts::ApplicationLayout`), exibido só para quem passa na policy.
- Rota própria (ex.: `resource :reports, only: :show` ou `get "relatorios"`; nome fica a cargo do builder).
- Policy nova (ex.: `ReportPolicy#show?` = `can_manage?`). Viewer recebe o mesmo tratamento de acesso negado já usado no app.

### Filtros (topo da página)

Filtros via query string (GET), para a URL poder ser compartilhada e o botão voltar funcionar.

| Filtro | Opções | Padrão |
|---|---|---|
| Mês | mês/ano | mês atual |
| Comparar com | mês anterior ao escolhido; mês atual | mês anterior |
| Produto | todos; cada produto da organização | todos |
| Vendedor | todos; usuários vinculados; nomes em texto sem vínculo; "Não vinculado" | todos |

- Mês futuro não é aceito; cai no mês atual.
- Decisão minha: com o mês atual escolhido, "Comparar com: mês atual" não faz sentido e vale como "mês anterior".
- Com produto escolhido, **todos** os números da página consideram só os itens daquele produto (receita = soma de `quantity * unit_price` dos itens; vendas = vendas que contêm o produto).
- Com vendedor escolhido, todos os números consideram só as vendas daquele vendedor.
- Decisão minha: as opções de vendedor listam os usuários membros da organização, os nomes em texto que aparecem em vendas dela e "Não vinculado".

### Bloco 1 — Indicadores (4 cards)

Para o mês escolhido, só vendas concluídas, com filtros aplicados:

- **Receita**
- **Vendas concluídas** (quantidade de vendas)
- **Unidades vendidas** (soma de `sale_items.quantity`)
- **Ticket médio** (receita ÷ vendas concluídas)

Cada card mostra:

- o valor do mês inteiro;
- variação % contra a base escolhida em "Comparar com", com ▲ verde ou ▼ vermelho;
- variação % contra o mês atual (omitida quando o mês escolhido já é o atual ou quando a base escolhida já é o mês atual);
- "—" quando a base é zero, como o dashboard faz hoje (`percentage_change` retorna `nil`).

Percentuais que envolvem o mês atual seguem a regra dos mesmos dias.

A unidade é genérica: o produto não tem unidade de medida, então "unidades" soma maço, kg, bandeja etc. Aceito pelo usuário como volume aproximado no total. Por produto, o número é exato.

### Bloco 2 — Pendentes e canceladas

Bloco separado, abaixo dos indicadores, com dois cards: **Pendentes** e **Canceladas**. Mês escolhido, mesmos filtros.

Decidido pelo usuário: cada card mostra quantidade, valor e percentual.

Decisões minhas sobre o percentual (o usuário não especificou qual):

- **Participação no mês:** quantas vendas do mês, de todos os status, estão naquele status. Ex.: "7,8% das vendas do mês" (12 de 154). Calculada por quantidade de vendas, sem recorte de dias.
- **Variação da quantidade** contra a base e contra o mês atual, no mesmo formato dos cards de indicadores e com a regra dos mesmos dias.
- Cores invertidas nesses dois cards: aumento em vermelho, queda em verde, porque mais pendentes ou canceladas é ruim.

### Bloco 3 — Evolução no ano

- Barras dos 12 meses do ano do mês escolhido, com receita de vendas concluídas.
- Acima de cada barra, variação % sobre o mês anterior. Janeiro compara com dezembro do ano anterior. A barra do mês atual compara pelos mesmos dias; a altura dela é o acumulado do mês até hoje.
- Mês escolhido destacado. Mês atual marcado como "em andamento". Meses futuros vazios.
- Barras feitas em HTML/CSS, sem biblioteca nova (decisão minha). Valor exato visível ao passar o mouse ou em texto acessível.
- Respeita os filtros de produto e vendedor.

### Bloco 4 — Produtos

Decidido pelo usuário: a tabela lista **todos os produtos que já tiveram ao menos uma venda concluída** na organização, mesmo os que não venderam no mês escolhido. Objetivo: ver o que deixou de vender.

- Colunas: produto, quantidade, receita, % da receita total do mês, variação % de quantidade contra a base.
- Ordem: quantidade decrescente, depois nome. Produtos com zero no mês ficam no fim, com a linha em tom apagado (decisão minha).
- Produto cadastrado que nunca teve venda concluída não aparece (decisão minha; o pedido foi "produtos vendidos").

Texto da variação (decisões minhas):

| Mês escolhido | Base | Mostra |
|---|---|---|
| > 0 | > 0 | % normal (▲/▼) |
| 0 | > 0 | ▼ 100% (parou de vender) |
| > 0 | 0, e a primeira venda concluída do produto é no mês escolhido | "novo" |
| > 0 | 0, mas o produto já vendeu antes | "—" |
| 0 | 0 | "—" |

- "novo" serve para acompanhar novas culturas. É calculado no nível da organização: a primeira venda concluída do produto, de qualquer vendedor.
- A lista de produtos não depende do filtro de vendedor; só os números dependem. Com um vendedor escolhido, produtos que ele nunca vendeu aparecem com zero. Com um produto escolhido, a tabela mostra só ele.

### Bloco 5 — Vendedores

Tabela ao lado de Produtos (empilha em tela pequena), ordenada por receita decrescente:

- vendedor, vendas, receita, % da receita total, variação % de receita contra a base.
- Agrupamento segue a regra da Parte 1: usuário vinculado → nome em texto → "Não vinculado". Nomes em texto aparecem com marcação "(importado)".
- Agrupar nomes em texto pelo valor normalizado, para "João" e "JOAO" não virarem duas linhas.

### Arquitetura sugerida

- Query object novo em `app/queries/reports/` (ex.: `Reports::MonthlyQuery`), no mesmo estilo de `Dashboard::OverviewQuery`: recebe organização, mês, base de comparação e filtros; expõe métricas e listas.
- Agregações no banco (SQL `SUM`/`COUNT`/`GROUP BY`), não em Ruby. A série anual pode sair de uma consulta agrupada por mês (`strftime('%Y-%m', sale_date)` no SQLite).
- Reaproveitar a lógica de `percentage_change`. Se ficar duplicada, extrair para um lugar comum.
- View Phlex em `app/views/reports/`, usando componentes RubyUI existentes (Card, Table, Select).

### Testes esperados

- Model: `Sale` com `seller`, validação de membership (só na criação ou troca de vendedor), nome exibido. `User`: excluir a conta desvincula as vendas e copia o `username` para `responsible_name`.
- Request: criação grava `Current.user` como vendedor; edição não muda vendedor; params não aceitam `seller_id`/`responsible_name`; relatórios acessíveis para owner/admin/manager e negados para viewer; excluir a conta com vendas funciona.
- Policy: `ReportPolicy`.
- Service: importador vincula por username normalizado, não vincula em ambiguidade ou ausência, mantém texto.
- Query: totais só de concluídas, filtros de produto e vendedor, percentuais, base zero, série anual, agrupamento de vendedores, isolamento por organização. Regra dos mesmos dias: mês passado contra mês atual, mês atual contra anterior, mês mais curto que `d`, barra do mês atual. Paridade com o dashboard no mês atual sem filtros: receita igual, e concluídas + pendentes + canceladas = "Vendas do mês". Produtos: zero no mês aparece com ▼ 100%, regra do "novo", produto nunca vendido fica de fora. Pendentes e canceladas: participação por quantidade e variação contra a base.

## Deixado para o builder

- Nomes de rota, controller, policy, query e componentes.
- Se o backfill de vendas antigas é migração ou rake task.
- Detalhes visuais (cores exatas, espaçamento), seguindo o padrão do dashboard.
- Componente do seletor de mês.
