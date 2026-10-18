/**
 * Regras de autorização das rotas admin (`server/**`) — lógica pura, testável
 * sem h3/Supabase.
 *
 * A fonte de verdade continua sendo o banco (RLS + checagens dentro das RPCs,
 * migration 0021); estas funções antecipam o 403 na borda com mensagem clara e
 * cobrem também o caso de usuário inativo (`profiles.ativo = false`), que não
 * deve operar nem via rotas com `service_role`.
 */

export interface PerfilAutorizacao {
  role: string
  ativo: boolean
  clube_id: string | null
}

/** Diretor Geral ativo. */
export function podeGerenciarUsuarios(perfil: PerfilAutorizacao | null | undefined): boolean {
  return !!perfil?.ativo && perfil.role === 'diretor_geral'
}

/**
 * Diretor Geral ou Diretor do clube da criança — mesmo escopo da autorização
 * dentro de `fn_transferir_oansista`.
 */
export function podeTransferirOansista(
  perfil: PerfilAutorizacao | null | undefined,
  clubeDaCrianca: string | null | undefined,
): boolean {
  if (!perfil?.ativo) return false
  if (perfil.role === 'diretor_geral') return true
  return perfil.role === 'diretor_clube'
    && !!perfil.clube_id
    && perfil.clube_id === clubeDaCrianca
}

/** Perfis que podem registrar um sábado perdido (backfill do encontro). */
const ROLES_RETRO = ['diretor_geral', 'secretaria', 'diretor_clube', 'lider']

export function podeCriarEncontroRetroativo(perfil: PerfilAutorizacao | null | undefined): boolean {
  return !!perfil?.ativo && ROLES_RETRO.includes(perfil.role)
}
