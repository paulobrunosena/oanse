<script setup lang="ts">
import { computed, ref } from 'vue'
import Button from 'primevue/button'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import type { EventoCor, EventoJogo, OansistaOpcao } from '@/composables/useJogos'
import { CORES_PREDEFINIDAS, corHex } from '@/utils/jogos'

const props = withDefaults(defineProps<{
  evento: EventoJogo
  oansistas?: OansistaOpcao[]
}>(), {
  oansistas: () => [],
})

const emit = defineEmits<{
  'adicionar-cor': [cor: string]
  'remover-cor': [corId: string]
  'adicionar-oansista': [corId: string, oansistaId: string]
  'remover-oansista': [corId: string, oansistaId: string]
  'finalizar': []
  'reabrir': []
  'excluir': []
}>()

const oansistaPorCor = ref<Record<string, string>>({})

const coresUsadas = computed(() => props.evento.cores.map(c => c.cor))
const coresDisponiveis = computed(() =>
  CORES_PREDEFINIDAS.filter(c => !coresUsadas.value.includes(c)),
)

function disponiveis(): OansistaOpcao[] {
  const usados = props.evento.cores.flatMap(c => c.oansistas.map(i => i.oansista_id))
  return props.oansistas.filter(o => !usados.includes(o.id))
}

function aoSelecionarOansista(cor: EventoCor) {
  const oansistaId = oansistaPorCor.value[cor.id]
  if (!oansistaId) return
  emit('adicionar-oansista', cor.id, oansistaId)
  oansistaPorCor.value[cor.id] = ''
}
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-4">
    <div class="flex items-start justify-between gap-3">
      <div class="min-w-0">
        <div class="flex items-center gap-2 flex-wrap">
          <span class="font-semibold">{{ evento.nome }}</span>
          <Tag
            v-for="clube in evento.clubes"
            :key="clube.clube_id"
            :value="clube.nome"
            :style="{ background: `${clube.cor ?? '#64748b'}20`, color: clube.cor ?? '#64748b' }"
          />
          <Tag
            :severity="evento.status === 'finalizado' ? 'success' : 'info'"
            :value="evento.status === 'finalizado' ? 'Finalizado' : 'Em andamento'"
          />
        </div>
        <p class="text-xs text-surface-500 mt-1">
          {{ evento.cores.length }} cor(es) participando · {{ evento.cores.reduce((n, c) => n + c.oansistas.length, 0) }} oansistas distribuídos
        </p>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <Button
          v-if="evento.status === 'em_andamento'"
          icon="pi pi-flag"
          label="Finalizar jogos"
          severity="success"
          size="small"
          @click="$emit('finalizar')"
        />
        <Button
          v-else
          icon="pi pi-replay"
          label="Reabrir"
          severity="secondary"
          text
          size="small"
          @click="$emit('reabrir')"
        />
        <Button
          v-if="evento.status === 'em_andamento'"
          icon="pi pi-trash"
          severity="danger"
          text
          size="small"
          title="Excluir evento"
          @click="$emit('excluir')"
        />
      </div>
    </div>

    <div class="mt-4 flex flex-col gap-3">
      <div
        v-for="cor in evento.cores"
        :key="cor.id"
        class="rounded-md border p-3"
      >
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-2 min-w-0">
            <span
              class="inline-block h-4 w-4 shrink-0 rounded-full border border-surface-300"
              :style="{ backgroundColor: corHex(cor.cor) }"
            />
            <span class="truncate font-medium text-sm capitalize">{{ cor.cor }}</span>
            <Tag
              severity="secondary"
              class="shrink-0"
            >
              {{ cor.oansistas.length }} criança(s)
            </Tag>
          </div>
          <Button
            icon="pi pi-times"
            severity="danger"
            text
            size="small"
            title="Remover cor"
            :disabled="evento.cores.length <= 2 || evento.status === 'finalizado'"
            @click="$emit('remover-cor', cor.id)"
          />
        </div>

        <div class="mt-3 flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <span class="text-xs text-surface-500 w-16 shrink-0">Oansistas</span>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="i in cor.oansistas"
                :key="i.oansista_id"
                class="inline-flex items-center gap-1"
              >
                <Tag
                  :value="i.nome"
                  rounded
                  removable
                  @remove="$emit('remover-oansista', cor.id, i.oansista_id)"
                />
                <Tag
                  v-if="i.clube && evento.clubes.length > 1"
                  :value="i.clube.nome"
                  class="text-[10px]"
                  :style="{ background: `${i.clube.cor ?? '#64748b'}20`, color: i.clube.cor ?? '#64748b' }"
                />
              </span>
              <span
                v-if="cor.oansistas.length === 0"
                class="text-xs text-surface-500"
              >
                Nenhuma criança nesta cor ainda.
              </span>
            </div>
          </div>
          <div
            v-if="evento.status === 'em_andamento'"
            class="flex items-center gap-2"
          >
            <span class="text-xs text-surface-500 w-16 shrink-0">Adicionar</span>
            <Select
              v-model="oansistaPorCor[cor.id]"
              :options="disponiveis()"
              option-label="nome"
              option-value="id"
              filter
              show-clear
              placeholder="Buscar criança"
              size="small"
              class="w-full max-w-xs"
              @update:model-value="aoSelecionarOansista(cor)"
            >
              <template #option="slotProps">
                <div class="flex items-center justify-between gap-2 w-full pr-4">
                  <span class="truncate">{{ slotProps.option.nome }}</span>
                  <Tag
                    v-if="slotProps.option.clube"
                    :value="slotProps.option.clube.nome"
                    :style="{ background: `${slotProps.option.clube.cor ?? '#64748b'}20`, color: slotProps.option.clube.cor ?? '#64748b' }"
                    class="shrink-0 text-xs"
                  />
                </div>
              </template>
            </Select>
          </div>
        </div>
      </div>

      <div
        v-if="coresDisponiveis.length && evento.status === 'em_andamento'"
        class="flex items-center gap-2"
      >
        <span class="text-sm">Adicionar cor:</span>
        <Button
          v-for="cor in coresDisponiveis"
          :key="cor"
          :label="cor"
          size="small"
          outlined
          class="capitalize"
          @click="$emit('adicionar-cor', cor)"
        />
      </div>
      <p
        v-else-if="coresDisponiveis.length === 0"
        class="text-xs text-surface-500"
      >
        Todas as 4 cores estão participando.
      </p>
    </div>
  </div>
</template>