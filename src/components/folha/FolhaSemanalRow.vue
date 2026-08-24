<script setup lang="ts">
import { computed, reactive } from 'vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import Checkbox from 'primevue/checkbox'
import InputNumber from 'primevue/inputnumber'
import Tag from 'primevue/tag'
import type { FormFolha } from '@/composables/useFolhaSemanal'
import { previewTotalFolha, type ItensPontuacaoMap } from '@/utils/pontos'

const props = defineProps<{
  nome: string
  folha: FormFolha | null
  presente: boolean
  pontos: ItensPontuacaoMap
  salvando: boolean
}>()

const emit = defineEmits<{ salvar: [form: FormFolha] }>()

const form = reactive<FormFolha>({
  uniforme: props.folha?.uniforme ?? false,
  biblia: props.folha?.biblia ?? false,
  ebd: props.folha?.ebd ?? false,
  manual: props.folha?.manual ?? false,
  conduta: props.folha?.conduta ?? false,
  secoes_dia: props.folha?.secoes_dia ?? 0,
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
    || form.secoes_dia !== f.secoes_dia
    || form.atividade_extra !== f.atividade_extra
})

const total = computed(() => previewTotalFolha(props.pontos, form, props.presente))

function salvar() {
  emit('salvar', { ...form })
}
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-4">
    <div class="flex items-center justify-between gap-3 mb-3">
      <div class="flex items-center gap-3 min-w-0">
        <Avatar
          :label="nome.charAt(0).toUpperCase()"
          size="small"
        />
        <span class="font-medium truncate">{{ nome }}</span>
      </div>
      <div class="flex items-center gap-2 shrink-0">
        <Tag severity="success">
          {{ total }} pts
        </Tag>
        <Button
          icon="pi pi-save"
          size="small"
          :disabled="!sujo"
          :loading="salvando"
          @click="salvar"
        >
          Salvar
        </Button>
      </div>
    </div>

    <div class="grid grid-cols-2 sm:grid-cols-3 gap-x-4 gap-y-3">
      <div class="flex items-center gap-2">
        <Checkbox
          v-model="form.uniforme"
          input-id="uniforme"
          binary
        />
        <label for="uniforme">Uniforme</label>
      </div>
      <div class="flex items-center gap-2">
        <Checkbox
          v-model="form.biblia"
          input-id="biblia"
          binary
        />
        <label for="biblia">Bíblia</label>
      </div>
      <div class="flex items-center gap-2">
        <Checkbox
          v-model="form.ebd"
          input-id="ebd"
          binary
        />
        <label for="ebd">EBD</label>
      </div>
      <div class="flex items-center gap-2">
        <Checkbox
          v-model="form.manual"
          input-id="manual"
          binary
        />
        <label for="manual">Manual</label>
      </div>
      <div class="flex items-center gap-2">
        <Checkbox
          v-model="form.conduta"
          input-id="conduta"
          binary
        />
        <label for="conduta">Conduta</label>
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-surface-500">Seções</span>
        <InputNumber
          v-model="(form.secoes_dia as any)"
          :min="0"
          :max="99"
          class="w-24"
        />
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-surface-500">Extra</span>
        <InputNumber
          v-model="(form.atividade_extra as any)"
          :min="0"
          :max="999"
          class="w-24"
        />
      </div>
    </div>
  </div>
</template>
