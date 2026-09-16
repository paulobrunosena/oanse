import { supabase } from '@/lib/supabase'

/**
 * Transferência de clube (mudança de faixa etária) — RN 9.
 * As regras de negócio (autorização, visitante no clube destino, histórico e
 * reversão) vivem nas RPCs `fn_transferir_clube`/`fn_cancelar_transferencia_clube`
 * (SECURITY DEFINER); aqui é apenas a fachada do cliente.
 */
export function useTransferenciaClube() {
  async function transferir(oansistaId: string, clubeDestinoId: string, motivo?: string | null): Promise<void> {
    const { error } = await supabase.rpc('fn_transferir_clube', {
      p_oansista_id: oansistaId,
      p_clube_destino_id: clubeDestinoId,
      p_motivo: motivo ?? undefined,
    })
    if (error) throw error
  }

  async function cancelar(oansistaId: string): Promise<void> {
    const { error } = await supabase.rpc('fn_cancelar_transferencia_clube', {
      p_oansista_id: oansistaId,
    })
    if (error) throw error
  }

  return { transferir, cancelar }
}
