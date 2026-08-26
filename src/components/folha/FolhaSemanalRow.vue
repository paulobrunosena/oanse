<script setup lang="ts">
import { computed, reactive } from 'vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import Checkbox from 'primevue/checkbox'
import InputNumber from 'primevue/inputnumber'
import Tag from 'primevue/tag'
import type { Folha, FormFolha } from '@/composables/useFolhaSemanal'
import { previewTotalFolha, type ItensPontuacaoMap } from '@/utils/pontos'
import { corHex, posicaoLabel } from '@/utils/jogos'

const props = withDefaults(defineProps<{
  nome: string
  folha: Folha | null
  presente: boolean
  pontos: ItensPontuacaoMap
  salvando: boolean
}>(), {})

const emit = defineEmits<{ salvar: [form: FormFolha] }>()

const form = reactive<FormFolha>({
  uniforme: props.folha?.uniforme ?? false,
  biblia: props.folha?.biblia ?? false,
  ebd: props.folha?.ebd ?? false,
  manual: props.folha?.manual ?? false,
  conduta: props.folha?.conduta ?? false,
  leitura_biblica: props.folha?.leitura_biblica ?? false,
  visitantes_convidados: props.folha?.visitantes_convidados ?? 0,
  secoes_sem_ajuda: props.folha?.secoes_sem_ajuda ?? 0,
  secoes_com_ajuda: props.folha?.secoes_com_ajuda ?? 0,
  atividade_extra: props.folha?.atividade_extra ?? 0,
})

const sujo = computed(() => {
  const f = props.folha
  if (!f) return true
  return form.uniforme !== f.uniforme
    || form.biblia !== f.biblia
    || form.ebd !== f.ebd
    || form.manual !== f.manual
    || form.conduta !== f.conduta
    || form.leitura_biblica !== f.leitura_biblica
    || form.visitantes_convidados !== f.visitantes_convidados
    || form.secoes_sem_ajuda !== f.secoes_sem_ajuda
    || form.secoes_com_ajuda !== f.secoes_com_ajuda
    || form.atividade_extra !== f.atividade_extra
})

const total = computed(() => previewTotalFolha(props.pontos, form, props.presente))

function salvar() {
  emit('salvar', { ...form })
}
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-4">
    <div class="flex items-center justify-between gap-3">
      <div class="flex items-center gap-3 min-w-0">
        <Avatar
          :label="nome.charAt(0).toUpperCase()"
          size="small"
        />
        <span class="truncate font-medium">{{ nome }}</span>
      </div>
      <Tag severity="success">
        {{ total }} pts
      </Tag>
    </div>

    <div class="mt-4 flex flex-col gap-4">
      <div class="grid grid-cols-1 gap-y-3 sm:grid-cols-2 sm:gap-x-6">
        <label
          class="flex items-center gap-2"
        >
          <Checkbox
            v-model="form.uniforme"
            binary
          />
          <span>Uniforme</span>
        </label>
        <label
          class="flex items-center gap-2"
        >
          <Checkbox
            v-model="form.biblia"
            binary
          />
          <span>Bíblia</span>
        </label>
        <label
          class="flex items-center gap-2"
        >
          <Checkbox
            v-model="form.ebd"
            binary
          />
          <span>EBD</span>
        </label>
        <label
          class="flex items-center gap-2"
        >
          <Checkbox
            v-model="form.manual"
            binary
          />
          <span>Manual</span>
        </label>
        <label
          class="flex items-center gap-2"
        >
          <Checkbox
            v-model="form.conduta"
            binary
          />
          <span>Conduta</span>
        </label>
        <label
          class="flex items-center gap-2"
        >
          <Checkbox
            v-model="form.leitura_biblica"
            binary
          />
          <span>Leitura bíblica</span>
        </label>
      </div>

      <div class="flex flex-col gap-3 rounded-md border p-3">
        <span class="text-sm font-semibold">Seções do manual</span>
        <div class="flex flex-col gap-3">
          <div class="flex items-center justify-between gap-2">
            <div class="flex flex-col">
              <span class="text-sm">Sem ajuda</span>
              <span class="text-xs text-surface-500">Vale mais pontos</span>
            </div>
            <InputNumber
              v-model="(form.secoes_sem_ajuda as any)"
              :min="0"
              :max="99"
              show-buttons
              button-layout="horizontal"
              increment-button-icon="pi pi-plus"
              decrement-button-icon="pi pi-minus"
              :input-style="{ minWidth: '0', width: '5rem', textAlign: 'center' }"
              class="w-36"
            />
          </div>
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm">Com ajuda</span>
            <InputNumber
              v-model="(form.secoes_com_ajuda as any)"
              :min="0"
              :max="99"
              show-buttons
              button-layout="horizontal"
              increment-button-icon="pi pi-plus"
              decrement-button-icon="pi pi-minus"
              :input-style="{ minWidth: '0', width: '5rem', textAlign: 'center' }"
              class="w-36"
            />
          </div>
        </div>
      </div>

      <div class="flex items-center justify-between gap-2">
        <span class="text-sm">Visitantes convidados</span>
        <InputNumber
          v-model="(form.visitantes_convidados as any)"
          :min="0"
          :max="99"
          show-buttons
          button-layout="horizontal"
          increment-button-icon="pi pi-plus"
          decrement-button-icon="pi pi-minus"
          :input-style="{ minWidth: '0', width: '5rem', textAlign: 'center' }"
          class="w-36"
        />
      </div>

      <div class="flex items-center justify-between gap-2">
        <span class="text-sm">Atividade extra</span>
        <InputNumber
          v-model="(form.atividade_extra as any)"
          :min="0"
          :max="999"
          show-buttons
          button-layout="horizontal"
          increment-button-icon="pi pi-plus"
          decrement-button-icon="pi pi-minus"
          :input-style="{ minWidth: '0', width: '5rem', textAlign: 'center' }"
          class="w-36"
        />
      </div>

      <div class="flex flex-col gap-2 rounded-md border p-3">
        <span class="text-sm font-semibold">Jogos do sábado</span>
        <div
          v-if="folha?.cor_time"
          class="flex flex-wrap items-center gap-2"
        >
          <span
            class="inline-block h-4 w-4 rounded-full border border-surface-300"
            :style="{ backgroundColor: corHex(folha.cor_time) }"
          />
          <span class="text-sm capitalize">{{ folha.cor_time }}</span>
          <span
            v-if="folha.posicao_jogos"
            class="text-sm font-medium"
          >
            {{ posicaoLabel(folha.posicao_jogos) }}
          </span>
          <span class="text-sm text-surface-500">
            {{ folha.pontos_jogos }} pts nos jogos
          </span>
        </div>
        <span
          v-else
          class="text-xs text-surface-500"
        >
          Não participou dos jogos deste sábado.
        </span>
      </div>
    </div>

    <div class="mt-4 flex justify-end">
      <Button
        icon="pi pi-save"
        label="Salvar"
        class="w-full sm:w-auto"
        :disabled="!sujo"
        :loading="salvando"
        @click="salvar"
      />
    </div>
  </div>
</template>