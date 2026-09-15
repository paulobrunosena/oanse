/**
 * Alerta sonoro leve (Web Audio API) para a chegada de novas pendências no
 * painel da Secretaria. Sem dependências externas; em ambientes sem áudio
 * (testes headless, browsers sem AudioContext) a função é um no-op seguro.
 */

let contexto: AudioContext | null = null

export function tocarSomAlerta() {
  try {
    const Ctx = window.AudioContext
      ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
    if (!Ctx) return

    contexto = contexto ?? new Ctx()
    const osc = contexto.createOscillator()
    const gain = contexto.createGain()

    osc.type = 'sine'
    osc.frequency.value = 880
    gain.gain.value = 0.04

    osc.connect(gain)
    gain.connect(contexto.destination)

    osc.start()
    osc.stop(contexto.currentTime + 0.15)
  }
  catch {
    // sem áudio disponível — ignora
  }
}
