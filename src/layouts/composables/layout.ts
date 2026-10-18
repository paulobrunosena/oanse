import { computed, reactive } from 'vue'

interface LayoutConfig {
  preset: string
  primary: string | null
  surface: string | null
  darkTheme: boolean
  menuMode: 'static' | 'overlay'
}

interface LayoutState {
  staticMenuInactive: boolean
  overlayMenuActive: boolean
  mobileMenuActive: boolean
  profileSidebarVisible: boolean
  configSidebarVisible: boolean
  sidebarExpanded: boolean
  menuHoverActive: boolean
  activeMenuItem: string | null
  activePath: string | null
}

const TEMA_ESCURO_KEY = 'oanse-tema-escuro'

function temaEscuroSalvo(): boolean {
  try {
    return localStorage.getItem(TEMA_ESCURO_KEY) === '1'
  }
  catch {
    return false
  }
}

const layoutConfig = reactive<LayoutConfig>({
  preset: 'Aura',
  primary: 'emerald',
  surface: null,
  darkTheme: temaEscuroSalvo(),
  menuMode: 'static',
})

// Aplica o tema salvo já no boot (o toggle também troca a classe).
document.documentElement.classList.toggle('app-dark', layoutConfig.darkTheme)

const layoutState = reactive<LayoutState>({
  staticMenuInactive: false,
  overlayMenuActive: false,
  mobileMenuActive: false,
  profileSidebarVisible: false,
  configSidebarVisible: false,
  sidebarExpanded: false,
  menuHoverActive: false,
  activeMenuItem: null,
  activePath: null,
})

export function useLayout() {
  const executeDarkModeToggle = () => {
    layoutConfig.darkTheme = !layoutConfig.darkTheme
    document.documentElement.classList.toggle('app-dark', layoutConfig.darkTheme)
    try {
      localStorage.setItem(TEMA_ESCURO_KEY, layoutConfig.darkTheme ? '1' : '0')
    }
    catch {
      // localStorage indisponível (modo privado) — o tema vale só na sessão.
    }
  }

  const toggleDarkMode = () => {
    const doc = document as Document & { startViewTransition?: (cb: () => void) => void }
    if (!doc.startViewTransition) {
      executeDarkModeToggle()
      return
    }
    doc.startViewTransition(() => executeDarkModeToggle())
  }

  const toggleMenu = () => {
    if (isDesktop()) {
      if (layoutConfig.menuMode === 'static') {
        layoutState.staticMenuInactive = !layoutState.staticMenuInactive
      }
      if (layoutConfig.menuMode === 'overlay') {
        layoutState.overlayMenuActive = !layoutState.overlayMenuActive
      }
    } else {
      layoutState.mobileMenuActive = !layoutState.mobileMenuActive
    }
  }

  const toggleConfigSidebar = () => {
    layoutState.configSidebarVisible = !layoutState.configSidebarVisible
  }

  const hideMobileMenu = () => {
    layoutState.mobileMenuActive = false
  }

  const changeMenuMode = (menuMode: 'static' | 'overlay') => {
    layoutConfig.menuMode = menuMode
    layoutState.staticMenuInactive = false
    layoutState.mobileMenuActive = false
    layoutState.sidebarExpanded = false
    layoutState.menuHoverActive = false
  }

  const isDarkTheme = computed(() => layoutConfig.darkTheme)
  const isDesktop = () => window.innerWidth > 991
  const hasOpenOverlay = computed(() => layoutState.overlayMenuActive)

  return {
    layoutConfig,
    layoutState,
    isDarkTheme,
    toggleDarkMode,
    toggleConfigSidebar,
    toggleMenu,
    hideMobileMenu,
    changeMenuMode,
    isDesktop,
    hasOpenOverlay,
  }
}
