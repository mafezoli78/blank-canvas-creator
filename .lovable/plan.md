## Plan: Nova Tela de Login Katuu

### Visão Geral

Redesenhar `Auth.tsx` para seguir a referência visual (fundo gradiente full-screen, 3 botões de login, termos no rodapé) e implementar fluxo de e-mail em etapas separadas. Substituir Instagram por Apple Sign In.

### Questão Importante: Apple Sign In

Supabase suporta Apple OAuth, mas requer configuração manual no Apple Developer Console e no dashboard do Supabase. Você precisará:

1. Criar um Services ID no Apple Developer Console
2. Gerar chave privada (.p8)
3. Configurar redirect URL do Supabase
4. Inserir Client ID e Client Secret no Supabase (Authentication → Providers → Apple)

O botão será implementado no código, mas só funcionará após essa configuração externa. Google OAuth também precisa estar configurado no dashboard do Supabase.

---

### Alterações

#### 1. Redesenhar `src/pages/Auth.tsx`

Substituir completamente o layout atual por uma tela full-screen com:

- Fundo gradiente (`#124854` → `#1F3A5F`) sem card branco
- Logo + ícone centralizados (assets existentes)
- "Bem-vindo de volta" / "Entre na sua conta para continuar" em branco
- 3 botões brancos arredondados com ícone à esquerda:
  - "Continuar com Google" → `signInWithOAuth({ provider: 'google' })`
  - "Continuar com Apple" → `signInWithOAuth({ provider: 'apple' })`
  - "Continuar com e-mail" → navega para estado de e-mail
- Rodapé: "Ao continuar, você concorda com os **Termos** e com a **Política de privacidade**" (links para `/terms` e `/privacy`)

Internamente usa state machine com `step`: `'main'` | `'email'` | `'password'` | `'register'` — tudo dentro de `Auth.tsx`, sem criar arquivos separados de página (mais simples, mesma UX).

- **Step email**: campo e-mail + "Continuar" + "Voltar". Ao submeter, chamar uma RPC segura check_email_exists no Supabase (criada previamente com SECURITY DEFINER) que retorna boolean indicando se o e-mail já possui conta. Se true → navegar para step 'password'. Se false → navegar para step 'register'.
- **Step password**: campo senha + "Entrar" + "Esqueci minha senha" + "Voltar"
- **Step register**: campos nome, e-mail (pré-preenchido, disabled), senha + "Criar conta"

#### 2. Atualizar `src/contexts/AuthContext.tsx`

Adicionar método `signInWithOAuth(provider: string)` ao contexto para Google e Apple.

#### 3. Criar `src/pages/Terms.tsx` e `src/pages/Privacy.tsx`

Páginas simples com conteúdo placeholder institucional, estilizadas com fundo branco e texto escuro. Facilmente editáveis.

#### 4. Adicionar rotas em `src/App.tsx`

- `/terms` → `Terms.tsx`
- `/privacy` → `Privacy.tsx`

#### 5. Criar `src/pages/ResetPassword.tsx`

Página para redefinição de senha (necessária para o fluxo "Esqueci minha senha"):

- Verifica `type=recovery` na URL
- Formulário para nova senha
- Chama `supabase.auth.updateUser({ password })`

Rota: `/reset-password`

---

### Arquivos modificados

- `src/pages/Auth.tsx` — redesign completo
- `src/contexts/AuthContext.tsx` — adicionar `signInWithOAuth`
- `src/App.tsx` — novas rotas

### Arquivos criados

- `src/pages/Terms.tsx`
- `src/pages/Privacy.tsx`
- `src/pages/ResetPassword.tsx`