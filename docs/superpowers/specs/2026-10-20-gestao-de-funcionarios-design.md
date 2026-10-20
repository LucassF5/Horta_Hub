# Gestão de funcionários da organização

Data: 2026-10-20

## Intenção

Hoje uma organização no Horta Hub só tem um membro: o dono criado no cadastro (`OrganizationsController#create`). Não existe tela para adicionar funcionários, então nenhum funcionário foi adicionado ainda. Esta feature cria uma aba dentro da organização para adicionar funcionários, escolher o cargo de cada um, trocar cargo e remover da organização.

A permissão vem do cargo. Não há tela de configurar permissões: os cargos são fixos, definidos no código, iguais para toda organização.

## Estado atual (base que já existe)

- `Membership` liga `User` a `Organization` com `role` em enum string: `owner`, `admin`, `manager`, `viewer` (`app/models/membership.rb`). Default `viewer`. Índice único `(organization_id, user_id)`.
- Um usuário pode pertencer a várias organizações; o seletor da sidebar troca a organização atual (`CurrentOrganizationsController`, `session[:organization_id]`).
- Autorização via ActionPolicy. `ApplicationPolicy` expõe `can_manage?` (owner, admin, manager) e `member?`. Viewer só lê. `ApplicationController` injeta `membership` e `organization` no contexto das policies.
- Views em Phlex + RubyUI. Padrão de CRUD em `app/views/clients/` e `.github/skills/novo-recurso-crud/SKILL.md`.
- Envio de e-mail não está configurado em produção (`config/environments/production.rb`, SMTP comentado).
- Turbo Drive ativo (`app/javascript/application.js`).

## Objetivos

1. Aba "Funcionários" na sidebar, visível só para owner e admin da organização atual.
2. Listar membros da organização atual: nome de usuário, e-mail, cargo.
3. Adicionar funcionário informando nome de usuário, e-mail e cargo. Sistema gera senha aleatória e mostra uma única vez na tela para copiar. Owner/admin repassa a senha por fora do sistema. Funcionário entra pela tela de login normal com essa senha.
4. Se o e-mail já tem conta (pessoa já está em outra organização), não criar conta nova: só criar a membership com o cargo escolhido. A senha dessa pessoa não muda e nenhuma senha é mostrada. Mensagem: usuário existente adicionado à organização.
5. Trocar cargo de um membro.
6. Remover membro da organização (apaga a membership, não a conta).
7. Cargos exibidos em português: Dono (`owner`), Administrador (`admin`), Gerente (`manager`), Visualizador (`viewer`).
8. Botão "Gerar nova senha" para recuperar acesso de funcionário que perdeu ou esqueceu a senha: gera senha aleatória nova, substitui a anterior e mostra uma única vez, igual à criação. É temporário: será retirado quando existir redefinição de senha por e-mail.

## Regras de permissão (decididas com o usuário)

- Só owner e admin acessam a aba e suas ações. Manager e viewer não veem o item na sidebar e recebem o tratamento padrão de `ActionPolicy::Unauthorized` se acessarem a URL.
- Ninguém atribui cargo acima do próprio. Admin não cria owner e não promove ninguém a owner.
- A organização nunca fica sem owner: o último owner não pode ser removido nem rebaixado.
- Owner não remove a si mesmo pela aba.
- Admin gerencia outros admins (mesmo nível), mas nunca owners.
- "Gerar nova senha" só funciona se o funcionário pertence **somente** à organização atual. Se ele tem membership em qualquer outra organização, o botão não aparece e a ação é negada no servidor. Motivo: a conta é compartilhada entre organizações; sem essa trava, admin da organização A poderia trocar a senha de alguém que é owner da organização B e entrar como ele lá.
- As permissões de cada cargo no resto do sistema continuam como estão hoje (owner/admin/manager editam tudo, viewer só lê). Diferenciação mais fina entre cargos virá no futuro; a modelagem não deve dificultar isso.

## Não-objetivos

- Cargos customizados criados pelo dono, ou tela de marcar permissões por cargo.
- Mudar o que manager ou viewer podem fazer em produtos, clientes, vendas e importações.
- E-mail de convite, redefinição de senha por e-mail, funcionário trocar a própria senha.
- Editar nome de usuário ou e-mail de um funcionário pela aba.

## Anti-objetivos (falha mesmo que funcione)

- Senha gerada gravada em texto puro em qualquer lugar (banco, log, cookie de sessão persistente) ou exibível de novo depois de sair da tela.
- Admin conseguir, por qualquer caminho (inclusive parâmetro manipulado no request), virar owner, criar owner, ou alterar/remover um owner.
- Membro de uma organização conseguir ver ou alterar memberships de outra organização.
- Funcionário removido continuar acessando dados da organização da qual saiu.
- Usuário removido de todas as organizações cair em loop de redirecionamento (ver Restrições).

## Restrições

- Seguir convenções do projeto: controller escopado em `Current.organization`, `authorize!` em toda action, strong params com `params.expect`, flash em português, views Phlex com RubyUI, policy com spec em `spec/policies/`, request spec em `spec/requests/`, factories em `spec/factories/`.
- O cargo enviado no formulário deve ser validado no servidor contra a lista de cargos que o usuário atual pode atribuir; não confiar no select da tela.
- `params` de senha já são filtrados de log (`filter_parameter_logging.rb` tem `:passw`). Senha gerada não deve passar por `params`.
- Loop existente a corrigir: se um usuário logado não tem nenhuma membership ativa, `set_current_organization` redireciona para `new_organization_path`, que é `unauthenticated_access_only` e redireciona de volta para `root`. Hoje isso quase não acontece; com remoção de membros passa a acontecer. Precisa ser tratado nesta feature.
- Rodar a suíte de qualidade do projeto (`.github/skills/rodar-qualidade/SKILL.md`: RuboCop, RSpec etc.) antes de considerar pronto.

## Decisões de comportamento

### Hierarquia de cargos

Ordem: `owner` > `admin` > `manager` > `viewer`.

| Ator | Pode atribuir | Pode alterar/remover membros com cargo |
|---|---|---|
| owner | owner, admin, manager, viewer | qualquer um, exceto a própria membership |
| admin | admin, manager, viewer | admin, manager, viewer (nunca owner), exceto a própria membership |

Regras do último owner valem para qualquer ator. "Gerar nova senha" segue a mesma coluna "pode alterar" da tabela, mais a trava de organização única.

### Gerar nova senha

- Disponível na lista, por membro, para owner/admin, respeitando a hierarquia acima e a trava de organização única.
- Nunca na própria membership (quem quer trocar a própria senha não usa esta aba).
- Substitui a senha da conta e encerra todas as sessões abertas do funcionário (`user.sessions.destroy_all`), para que a senha antiga e sessões antigas parem de valer.
- Mostra a senha nova uma única vez, na mesma tela de resultado usada na criação, com as mesmas restrições de não persistir.

### Adicionar funcionário

- Campos: nome de usuário, e-mail, cargo.
- E-mail novo: cria `User` com senha aleatória gerada por `SecureRandom` e cria `Membership`, na mesma transação.
- E-mail já cadastrado e já membro desta organização: erro de validação, nada muda.
- E-mail já cadastrado em outra organização: cria só a `Membership`. Nome de usuário digitado é ignorado (mantém o da conta existente). Nenhuma senha mostrada.
- Tela de resultado (conta nova): mostra e-mail e senha gerada com botão de copiar, aviso de que a senha não será mostrada de novo, e link de volta para a lista.

### Remover funcionário

- Apaga a `Membership`. A conta (`User`) fica, porque importações (`ImportBatch`) pertencem ao usuário e são `dependent: :destroy`; apagar a conta apagaria histórico da organização.
- Se o usuário removido não tem mais nenhuma membership ativa, encerrar todas as sessões dele (`user.sessions.destroy_all`).
- Se ele ainda tem outras organizações, as sessões continuam; na próxima requisição `selected_membership` não acha mais a organização removida e `default_membership` cai em outra.

## Chamadas minhas (não discutidas com o usuário; confira)

- Nome da aba "Funcionários", ícone Lucide de pessoas, posição depois de "Importações".
- Rota sugerida `resources :memberships` (ou `members`) em `index new create edit update destroy`, mais uma ação de membro para gerar nova senha, escopada na organização atual. Sem `show` além da tela de senha gerada.
- Ninguém edita ou remove a própria membership pela aba (inclui admin se rebaixar).
- Senha gerada: 8 caracteres (decisão do usuário, para não ficar extensa), `SecureRandom.alphanumeric(8)` ou equivalente legível.
- Membro sem nenhuma organização ativa que tenta navegar: sessão encerrada e redirecionado para login com alerta "Você não pertence a nenhuma organização." (corrige o loop).
- Lista ordenada por cargo (owner primeiro) e depois por nome de usuário.

## Riscos conhecidos, fora desta feature

- Usuário removido de todas as organizações não consegue criar organização própria com o mesmo e-mail: `OrganizationsController#new/create` é só para quem não está logado e sempre cria `User` novo, e o e-mail é único. Ele é deslogado e não tem para onde ir.
- `DELETE /users/:id` (`UsersController#destroy`) existe sem link na interface e qualquer usuário logado pode chamar. Se o último owner apagar a própria conta, a organização fica sem owner. Se um funcionário apagar, as importações dele (`ImportBatch`, `dependent: :destroy`) somem de todas as organizações. Não tratar agora; registrar para uma feature futura.

## Deixado para o builder

- Como entregar a senha gerada sem persistir: por exemplo, renderizar a tela de resultado direto na resposta do `create` com o formulário marcado `data: { turbo: false }`, ou outra abordagem que respeite os anti-objetivos. Flash em cookie não é aceitável.
- Onde colocar a lógica de hierarquia (métodos no `Membership`, constante de ordem dos cargos, policy) e de criação (objeto de serviço ou model). Deixar preparado para cargos ganharem permissões diferentes depois.
- Tradução dos cargos (I18n ou helper), desde que reutilizável nas telas.
- Detalhes de layout, seguindo o padrão das telas de Clientes.
- Cobertura de testes: policy spec por cargo e por regra de hierarquia, request spec para cada action incluindo parâmetro de cargo manipulado e acesso cruzado entre organizações, trava de organização única no "Gerar nova senha", e teste do fim do loop de redirecionamento.
