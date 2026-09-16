import { config } from '@vue/test-utils'
import Tooltip from 'primevue/tooltip'

config.global.directives = {
  tooltip: Tooltip,
}
