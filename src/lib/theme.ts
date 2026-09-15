import Aura from '@primeuix/themes/aura-compat'

export const primevuePreset = {
  ...Aura,
  components: {
    ...Aura.components,
    tabs: {
      ...Aura.components!.tabs,
      tab: {
        ...Aura.components!.tabs!.tab,
        borderWidth: '0',
        borderColor: 'transparent',
        hoverBorderColor: 'transparent',
        activeBorderColor: 'transparent',
        margin: '0',
      },
      activeBar: {
        ...Aura.components!.tabs!.activeBar,
        bottom: '0',
      },
    },
  },
}
