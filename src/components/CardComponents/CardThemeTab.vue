<template>
    <!-- Outer wrapper: phone LEFT (sticky), controls RIGHT -->
    <div class="flex flex-col lg:flex-row gap-6 items-start">

        <!-- ═══════════════════════════════════════════
             LEFT — Live phone preview (sticky)
             Hidden on mobile; shown inline below controls
             ═══════════════════════════════════════════ -->
        <div v-if="canCustomizeTheme" class="hidden lg:flex flex-col items-center gap-4 lg:sticky lg:top-4 flex-shrink-0">
            <!-- Phone -->
            <div class="theme-phone-simulator" :style="{ '--sim-width': '220px' }">
                <div class="theme-phone-screen" :style="simulatorBgStyle">
                    <!-- Status bar -->
                    <div class="theme-status-bar">
                        <span class="theme-status-time">9:41</span>
                        <div class="flex items-center gap-1">
                            <i class="pi pi-wifi"         style="font-size: 0.55rem; opacity: 0.8"></i>
                            <i class="pi pi-signal-bars"  style="font-size: 0.55rem; opacity: 0.8"></i>
                            <i class="pi pi-battery"      style="font-size: 0.55rem; opacity: 0.8"></i>
                        </div>
                    </div>
                    <!-- Hero -->
                    <div class="theme-hero-area" :style="simulatorHeroStyle">
                        <div class="theme-hero-icon" :style="simulatorPrimaryStyle">
                            <i class="pi pi-sparkles" style="font-size: 0.65rem;"></i>
                        </div>
                        <div class="theme-hero-text">
                            <div class="theme-hero-title"    :style="simulatorTextStyle"></div>
                            <div class="theme-hero-subtitle" :style="simulatorSubtextStyle"></div>
                        </div>
                    </div>
                    <!-- Content list -->
                    <div class="theme-content-area">
                        <div v-for="n in 5" :key="n" class="theme-content-item" :style="simulatorCardStyle">
                            <div class="theme-item-dot" :style="simulatorPrimaryStyle"></div>
                            <div class="theme-item-lines">
                                <div class="theme-item-line-title"
                                     :style="[simulatorTextStyle, { width: [80,55,75,65,85][n-1] + '%' }]">
                                </div>
                                <div class="theme-item-line-sub" :style="simulatorSubtextStyle"></div>
                            </div>
                        </div>
                    </div>
                    <!-- Bottom FAB -->
                    <div class="theme-bottom-bar">
                        <div class="theme-action-btn" :style="simulatorPrimaryStyle">
                            <i class="pi pi-comments" style="font-size: 0.6rem"></i>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Label + color dots below phone -->
            <div class="text-center">
                <p class="text-sm font-semibold text-slate-700 m-0">
                    <span v-if="activePresetKey">{{ $t(`dashboard.theme_preset_${activePresetKey}`) }}</span>
                    <span v-else-if="hasWorkingTheme">{{ $t('dashboard.theme_preset_custom') }}</span>
                    <span v-else>{{ $t('dashboard.theme_default') }}</span>
                </p>
                <p class="text-xs text-slate-400 m-0 mt-0.5">{{ $t('dashboard.theme_preview') }}</p>
                <!-- Color dots row — luminance-aware borders for light colors -->
                <div class="flex items-center justify-center gap-1.5 mt-2">
                    <div v-for="(colorKey, dotIdx) in ['backgroundColor','gradientEndColor','primaryColor','textColor']"
                         :key="dotIdx"
                         class="w-4 h-4 rounded-full shadow-sm transition-colors duration-200"
                         :style="colorDotStyle(localTheme[colorKey])">
                    </div>
                </div>
            </div>
        </div>

        <!-- ═══════════════════════════════════════════
             RIGHT (or full-width on mobile) — Controls
             ═══════════════════════════════════════════ -->
        <div class="flex-1 min-w-0 flex flex-col gap-5">

            <!-- ── Upgrade gate ─────────────────────── -->
            <div v-if="!canCustomizeTheme"
                 class="rounded-2xl overflow-hidden border border-amber-200 bg-gradient-to-br from-amber-50 to-orange-50">
                <div class="p-5 flex items-start gap-4">
                    <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center shrink-0">
                        <i class="pi pi-lock text-amber-600"></i>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h3 class="text-sm font-semibold text-amber-900 m-0 mb-1">
                            {{ $t('dashboard.theme_upgrade_title') }}
                        </h3>
                        <p class="text-xs text-amber-700 m-0 leading-relaxed">
                            {{ $t('dashboard.theme_upgrade_hint') }}
                        </p>
                        <Button
                            :label="$t('subscription.upgrade_to_premium')"
                            icon="pi pi-arrow-up-right"
                            severity="warning"
                            size="small"
                            class="mt-3"
                            @click="router.push(`/${currentLang}/dashboard/subscription`)"
                        />
                    </div>
                </div>
                <!-- Greyed preview of swatches to entice upgrade -->
                <div class="border-t border-amber-200 px-5 py-4 bg-amber-50/50">
                    <p class="text-xs font-semibold uppercase tracking-wider text-amber-600 m-0 mb-3">
                        {{ $t('dashboard.theme_locked_preview') }}
                    </p>
                    <div class="flex flex-wrap gap-2 opacity-40 pointer-events-none select-none">
                        <div v-for="preset in THEME_PRESETS.slice(0, 10)" :key="preset.key"
                             class="w-10 h-10 rounded-xl border-2 border-transparent overflow-hidden"
                             :style="{ background: `linear-gradient(135deg, ${preset.theme.backgroundColor} 0%, ${preset.theme.gradientEndColor} 100%)` }">
                        </div>
                        <div class="flex items-center text-xs text-amber-700 font-medium px-2">
                            +{{ THEME_PRESETS.length - 10 }} more
                        </div>
                    </div>
                </div>
            </div>

            <!-- ── Preset grid ──────────────────────── -->
            <div v-if="canCustomizeTheme" class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-semibold text-slate-800 m-0">{{ $t('dashboard.theme_presets') }}</h3>
                        <p class="text-xs text-slate-400 m-0 mt-0.5">{{ $t('dashboard.theme_presets_hint') }}</p>
                    </div>
                    <!-- Active preset badge -->
                    <span v-if="activePresetKey"
                          class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-50 text-indigo-600 border border-indigo-100">
                        <i class="pi pi-check text-[10px]"></i>
                        {{ $t(`dashboard.theme_preset_${activePresetKey}`) }}
                    </span>
                </div>

                <div class="p-5 flex flex-col gap-5">
                    <!-- Dark presets -->
                    <div>
                        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
                            {{ $t('dashboard.theme_presets_dark') }}
                        </p>
                        <div class="grid grid-cols-5 sm:grid-cols-10 gap-2">
                            <button
                                v-for="preset in darkPresets"
                                :key="preset.key"
                                type="button"
                                :title="$t(`dashboard.theme_preset_${preset.key}`)"
                                :class="[
                                    'theme-preset-swatch group relative rounded-xl overflow-hidden cursor-pointer border-2 transition-all duration-150',
                                    isActivePreset(preset)
                                        ? 'border-indigo-500 shadow-lg scale-110'
                                        : 'border-transparent hover:border-slate-400 hover:scale-[1.05]'
                                ]"
                                @click="applyPreset(preset)"
                                @mouseenter="hoveredPreset = preset.key"
                                @mouseleave="hoveredPreset = null"
                                @focus="hoveredPreset = preset.key"
                                @blur="hoveredPreset = null"
                            >
                                <div class="w-full aspect-square flex flex-col justify-between p-1.5"
                                     :style="{ background: `linear-gradient(135deg, ${preset.theme.backgroundColor} 0%, ${preset.theme.gradientEndColor} 100%)` }">
                                    <div class="flex flex-col gap-0.5">
                                        <div class="h-1 rounded-full w-3/4 opacity-80" :style="{ background: preset.theme.textColor }"></div>
                                        <div class="h-0.5 rounded-full w-1/2 opacity-40" :style="{ background: preset.theme.textColor }"></div>
                                    </div>
                                    <div class="flex justify-end">
                                        <div class="w-2.5 h-2.5 rounded-full" :style="{ background: preset.theme.primaryColor }"></div>
                                    </div>
                                </div>
                                <div v-if="isActivePreset(preset)"
                                     class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-indigo-500 flex items-center justify-center shadow">
                                    <i class="pi pi-check text-white" style="font-size: 0.45rem"></i>
                                </div>
                            </button>
                        </div>
                        <!-- Hover label row -->
                        <Transition name="fade-status">
                            <p v-if="hoveredPreset && darkPresets.some(p => p.key === hoveredPreset)"
                               class="text-xs text-slate-500 mt-2 mb-0 font-medium">
                                {{ $t(`dashboard.theme_preset_${hoveredPreset}`) }}
                            </p>
                        </Transition>
                    </div>

                    <!-- Light presets -->
                    <div>
                        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
                            {{ $t('dashboard.theme_presets_light') }}
                        </p>
                        <div class="grid grid-cols-5 sm:grid-cols-10 gap-2">
                            <button
                                v-for="preset in lightPresets"
                                :key="preset.key"
                                type="button"
                                :title="$t(`dashboard.theme_preset_${preset.key}`)"
                                :class="[
                                    'theme-preset-swatch group relative rounded-xl overflow-hidden cursor-pointer border-2 transition-all duration-150',
                                    isActivePreset(preset)
                                        ? 'border-indigo-500 shadow-lg scale-110'
                                        : 'border-slate-200 hover:border-slate-400 hover:scale-[1.05]'
                                ]"
                                @click="applyPreset(preset)"
                                @mouseenter="hoveredPreset = preset.key"
                                @mouseleave="hoveredPreset = null"
                                @focus="hoveredPreset = preset.key"
                                @blur="hoveredPreset = null"
                            >
                                <div class="w-full aspect-square flex flex-col justify-between p-1.5"
                                     :style="{ background: `linear-gradient(135deg, ${preset.theme.backgroundColor} 0%, ${preset.theme.gradientEndColor} 100%)` }">
                                    <div class="flex flex-col gap-0.5">
                                        <div class="h-1 rounded-full w-3/4 opacity-80" :style="{ background: preset.theme.textColor }"></div>
                                        <div class="h-0.5 rounded-full w-1/2 opacity-40" :style="{ background: preset.theme.textColor }"></div>
                                    </div>
                                    <div class="flex justify-end">
                                        <div class="w-2.5 h-2.5 rounded-full" :style="{ background: preset.theme.primaryColor }"></div>
                                    </div>
                                </div>
                                <div v-if="isActivePreset(preset)"
                                     class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-indigo-500 flex items-center justify-center shadow">
                                    <i class="pi pi-check text-white" style="font-size: 0.45rem"></i>
                                </div>
                            </button>
                        </div>
                        <!-- Hover label row -->
                        <Transition name="fade-status">
                            <p v-if="hoveredPreset && lightPresets.some(p => p.key === hoveredPreset)"
                               class="text-xs text-slate-500 mt-2 mb-0 font-medium">
                                {{ $t(`dashboard.theme_preset_${hoveredPreset}`) }}
                            </p>
                        </Transition>
                    </div>
                </div>
            </div>

            <!-- ── Custom color pickers ─────────────── -->
            <div v-if="canCustomizeTheme" class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                <div class="px-5 py-4 border-b border-slate-100">
                    <h3 class="text-sm font-semibold text-slate-800 m-0">{{ $t('dashboard.theme_custom_colors') }}</h3>
                    <p class="text-xs text-slate-400 m-0 mt-0.5">{{ $t('dashboard.theme_custom_colors_hint') }}</p>
                </div>
                <div class="p-5 flex flex-col gap-4">

                    <!-- Group 1: Accent + Text (independent colors) -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                        <label v-for="field in accentTextFields" :key="field.key"
                               class="flex items-center gap-3 px-3 py-2.5 rounded-xl border border-slate-100 hover:border-indigo-200 hover:bg-indigo-50/30 transition-all cursor-pointer group">
                            <div class="relative flex-shrink-0">
                                <!-- Color swatch with luminance-aware border ring -->
                                <div class="w-9 h-9 rounded-lg shadow-sm transition-transform group-hover:scale-105"
                                     :style="colorSwatchStyle(localTheme[field.key])">
                                </div>
                                <input type="color" :value="localTheme[field.key]"
                                       @input="updateThemeColor(field.key, $event.target.value)"
                                       class="absolute inset-0 w-full h-full opacity-0 cursor-pointer" />
                            </div>
                            <div class="min-w-0 flex-1">
                                <p class="text-sm font-medium text-slate-700 m-0 leading-snug">{{ $t(field.labelKey) }}</p>
                                <p class="text-[10px] font-mono text-slate-400 m-0">{{ localTheme[field.key] }}</p>
                                <p class="text-[11px] text-slate-400 m-0 leading-tight hidden sm:block">{{ $t(field.hintKey) }}</p>
                            </div>
                        </label>
                    </div>

                    <!-- Divider -->
                    <div class="flex items-center gap-3">
                        <div class="flex-1 border-t border-slate-100"></div>
                        <span class="text-[11px] font-semibold uppercase tracking-wider text-slate-400">{{ $t('dashboard.theme_background_group') }}</span>
                        <div class="flex-1 border-t border-slate-100"></div>
                    </div>

                    <!-- Group 2: Background pair — shown side-by-side with gradient preview -->
                    <div class="rounded-xl border border-slate-100 overflow-hidden">
                        <!-- Gradient preview strip -->
                        <div class="h-10 w-full transition-all duration-300"
                             :style="{ background: `linear-gradient(to right, ${localTheme.backgroundColor}, ${localTheme.gradientEndColor})` }">
                        </div>
                        <!-- Two pickers side by side -->
                        <div class="grid grid-cols-2 divide-x divide-slate-100">
                            <label v-for="field in backgroundFields" :key="field.key"
                                   class="flex items-center gap-2.5 p-3 hover:bg-indigo-50/30 transition-colors cursor-pointer group">
                                <div class="relative flex-shrink-0">
                                    <div class="w-9 h-9 rounded-lg shadow-sm transition-transform group-hover:scale-105"
                                         :style="colorSwatchStyle(localTheme[field.key])">
                                    </div>
                                    <input type="color" :value="localTheme[field.key]"
                                           @input="updateThemeColor(field.key, $event.target.value)"
                                           class="absolute inset-0 w-full h-full opacity-0 cursor-pointer" />
                                </div>
                                <div class="min-w-0">
                                    <p class="text-xs font-medium text-slate-700 m-0 leading-tight">{{ $t(field.labelKey) }}</p>
                                    <p class="text-[10px] font-mono text-slate-400 m-0">{{ localTheme[field.key] }}</p>
                                </div>
                            </label>
                        </div>
                    </div>

                </div>
            </div>

            <!-- Mobile-only preview (below controls, < lg) -->
            <div v-if="canCustomizeTheme" class="lg:hidden flex flex-col items-center gap-3 py-2">
                <p class="text-xs font-semibold uppercase tracking-wider text-slate-400 self-start">
                    {{ $t('dashboard.theme_preview') }}
                </p>
                <div class="theme-phone-simulator" :style="{ '--sim-width': '180px' }">
                    <div class="theme-phone-screen" :style="simulatorBgStyle">
                        <div class="theme-status-bar">
                            <span class="theme-status-time">9:41</span>
                            <div class="flex items-center gap-1">
                                <i class="pi pi-wifi"    style="font-size: 0.55rem; opacity: 0.8"></i>
                                <i class="pi pi-battery" style="font-size: 0.55rem; opacity: 0.8"></i>
                            </div>
                        </div>
                        <div class="theme-hero-area" :style="simulatorHeroStyle">
                            <div class="theme-hero-icon" :style="simulatorPrimaryStyle">
                                <i class="pi pi-sparkles" style="font-size: 0.65rem;"></i>
                            </div>
                            <div class="theme-hero-text">
                                <div class="theme-hero-title"    :style="simulatorTextStyle"></div>
                                <div class="theme-hero-subtitle" :style="simulatorSubtextStyle"></div>
                            </div>
                        </div>
                        <div class="theme-content-area">
                            <div v-for="n in 4" :key="n" class="theme-content-item" :style="simulatorCardStyle">
                                <div class="theme-item-dot" :style="simulatorPrimaryStyle"></div>
                                <div class="theme-item-lines">
                                    <div class="theme-item-line-title"
                                         :style="[simulatorTextStyle, { width: [80,60,75,65][n-1] + '%' }]">
                                    </div>
                                    <div class="theme-item-line-sub" :style="simulatorSubtextStyle"></div>
                                </div>
                            </div>
                        </div>
                        <div class="theme-bottom-bar">
                            <div class="theme-action-btn" :style="simulatorPrimaryStyle">
                                <i class="pi pi-comments" style="font-size: 0.6rem"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ── Save / Reset actions ─────────────── -->
            <div v-if="canCustomizeTheme"
                 class="flex items-center gap-3 flex-wrap px-1">
                <Button
                    :label="isSaving ? $t('common.saving') : $t('dashboard.save_changes')"
                    icon="pi pi-save"
                    severity="primary"
                    :loading="isSaving"
                    :disabled="!hasUnsavedChanges || isSaving"
                    @click="saveTheme"
                />
                <Button
                    :label="$t('dashboard.theme_reset_default')"
                    icon="pi pi-refresh"
                    severity="secondary"
                    outlined
                    :disabled="!hasWorkingTheme && !hasUnsavedChanges"
                    @click="resetThemeColors"
                />
                <!-- Status indicator -->
                <Transition name="fade-status">
                    <span v-if="hasUnsavedChanges"
                          class="text-xs text-amber-600 flex items-center gap-1">
                        <i class="pi pi-exclamation-circle text-xs"></i>
                        {{ $t('dashboard.unsaved_changes') }}
                    </span>
                    <span v-else-if="justSaved"
                          class="text-xs text-emerald-600 flex items-center gap-1">
                        <i class="pi pi-check-circle text-xs"></i>
                        {{ $t('dashboard.saved') }}
                    </span>
                </Transition>
            </div>

        </div><!-- end controls column -->

    </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import Button from 'primevue/button';
import { useSubscriptionStore } from '@/stores/subscription';
import { DEFAULT_THEME, isValidHexColor } from '@/utils/themeConfig';
import { useToast } from 'primevue/usetoast';

const { t } = useI18n();
const router = useRouter();
const route  = useRoute();
const subscriptionStore = useSubscriptionStore();
const toast = useToast();

const props = defineProps({
    card:         { type: Object,   default: null },
    updateCardFn: { type: Function, default: null }
});

const emit = defineEmits(['update-card']);

const currentLang = computed(() => route.params.lang || 'en');

// ── Subscription gate ───────────────────────────────────────────────────────
const canCustomizeTheme = computed(() => {
    const tier = subscriptionStore.tier;
    return tier === 'premium' || tier === 'enterprise';
});

// ── Presets ─────────────────────────────────────────────────────────────────
const THEME_PRESETS = [
    // Dark
    { key: 'midnight', theme: { primaryColor: '#6366f1', backgroundColor: '#0f172a', gradientEndColor: '#4338ca', textColor: '#ffffff' } },
    { key: 'ocean',    theme: { primaryColor: '#38bdf8', backgroundColor: '#0c1a2e', gradientEndColor: '#0369a1', textColor: '#e0f2fe' } },
    { key: 'forest',   theme: { primaryColor: '#4ade80', backgroundColor: '#052e16', gradientEndColor: '#166534', textColor: '#f0fdf4' } },
    { key: 'sunset',   theme: { primaryColor: '#fb923c', backgroundColor: '#1c0a00', gradientEndColor: '#9a3412', textColor: '#fff7ed' } },
    { key: 'rose',     theme: { primaryColor: '#f43f5e', backgroundColor: '#1a0010', gradientEndColor: '#881337', textColor: '#fff1f2' } },
    { key: 'violet',   theme: { primaryColor: '#c084fc', backgroundColor: '#1a0a2e', gradientEndColor: '#7e22ce', textColor: '#faf5ff' } },
    { key: 'gold',     theme: { primaryColor: '#fbbf24', backgroundColor: '#1a1000', gradientEndColor: '#92400e', textColor: '#fffbeb' } },
    { key: 'slate',    theme: { primaryColor: '#94a3b8', backgroundColor: '#0f172a', gradientEndColor: '#334155', textColor: '#f8fafc' } },
    { key: 'teal',     theme: { primaryColor: '#2dd4bf', backgroundColor: '#042f2e', gradientEndColor: '#0f766e', textColor: '#f0fdfa' } },
    { key: 'crimson',  theme: { primaryColor: '#ef4444', backgroundColor: '#0f0a0a', gradientEndColor: '#7f1d1d', textColor: '#ffffff' } },
    // Light
    { key: 'cloud',    theme: { primaryColor: '#6366f1', backgroundColor: '#f8fafc', gradientEndColor: '#e2e8f0', textColor: '#1e293b' } },
    { key: 'blossom',  theme: { primaryColor: '#e11d48', backgroundColor: '#fff1f2', gradientEndColor: '#fce7f3', textColor: '#881337' } },
    { key: 'meadow',   theme: { primaryColor: '#16a34a', backgroundColor: '#f0fdf4', gradientEndColor: '#dcfce7', textColor: '#14532d' } },
    { key: 'sky',      theme: { primaryColor: '#0284c7', backgroundColor: '#f0f9ff', gradientEndColor: '#dbeafe', textColor: '#0c4a6e' } },
    { key: 'sand',     theme: { primaryColor: '#d97706', backgroundColor: '#fffbeb', gradientEndColor: '#fef3c7', textColor: '#78350f' } },
    { key: 'lavender', theme: { primaryColor: '#7c3aed', backgroundColor: '#faf5ff', gradientEndColor: '#ede9fe', textColor: '#4c1d95' } },
    { key: 'peach',    theme: { primaryColor: '#ea580c', backgroundColor: '#fff7ed', gradientEndColor: '#fed7aa', textColor: '#7c2d12' } },
    { key: 'arctic',   theme: { primaryColor: '#0891b2', backgroundColor: '#ecfeff', gradientEndColor: '#cffafe', textColor: '#164e63' } },
];

const darkPresets  = computed(() => THEME_PRESETS.filter(p => !isLightTheme(p)));
const lightPresets = computed(() => THEME_PRESETS.filter(p =>  isLightTheme(p)));

// ── Color picker field definitions ─────────────────────────────────────────
// Accent + Text — independent, shown as a 2-col grid
const accentTextFields = [
    { key: 'primaryColor', labelKey: 'dashboard.theme_primary_color', hintKey: 'dashboard.theme_primary_color_hint' },
    { key: 'textColor',    labelKey: 'dashboard.theme_text_color',    hintKey: 'dashboard.theme_text_color_hint'    },
];
// Background pair — shown together with a gradient strip preview
const backgroundFields = [
    { key: 'backgroundColor',  labelKey: 'dashboard.theme_background_color',   hintKey: 'dashboard.theme_background_color_hint'   },
    { key: 'gradientEndColor', labelKey: 'dashboard.theme_gradient_end_color', hintKey: 'dashboard.theme_gradient_end_color_hint' },
];

// ── Local working copy ──────────────────────────────────────────────────────
const localTheme = reactive({ ...DEFAULT_THEME });
const savedTheme = ref({});

const initFromCard = () => {
    const theme = props.card?.metadata?.theme || {};
    Object.assign(localTheme, { ...DEFAULT_THEME, ...theme });
    savedTheme.value = { ...theme };
};

watch(() => props.card?.id,              () => initFromCard(), { immediate: true });
watch(() => props.card?.metadata?.theme, () => initFromCard(), { deep: true });

// ── State flags ─────────────────────────────────────────────────────────────
const hasUnsavedChanges = computed(() => {
    const saved = savedTheme.value;
    const keys  = ['primaryColor', 'backgroundColor', 'gradientEndColor', 'textColor'];
    if (!saved || Object.keys(saved).length === 0) {
        return keys.some(k => localTheme[k] !== DEFAULT_THEME[k]);
    }
    return keys.some(k => localTheme[k] !== (saved[k] ?? DEFAULT_THEME[k]));
});

// Whether the localTheme has *any* non-default value right now
const hasWorkingTheme = computed(() => {
    const keys = ['primaryColor', 'backgroundColor', 'gradientEndColor', 'textColor'];
    return keys.some(k => localTheme[k] !== DEFAULT_THEME[k]);
});

const isSaving      = ref(false);
const justSaved     = ref(false);
const hoveredPreset = ref(null);

// ── Save ────────────────────────────────────────────────────────────────────
const saveTheme = async () => {
    if (!props.updateCardFn) return;
    isSaving.value  = true;
    justSaved.value = false;
    try {
        const themeToSave = {
            primaryColor:     localTheme.primaryColor,
            backgroundColor:  localTheme.backgroundColor,
            gradientEndColor: localTheme.gradientEndColor,
            textColor:        localTheme.textColor,
        };
        const payload = {
            ...props.card,
            metadata: { ...(props.card?.metadata || {}), theme: themeToSave }
        };
        await props.updateCardFn(payload);
        savedTheme.value = { ...themeToSave };
        justSaved.value  = true;
        setTimeout(() => { justSaved.value = false; }, 3000);
        toast.add({ severity: 'success', summary: t('dashboard.theme_saved'),
                    detail: t('dashboard.theme_saved_detail'), life: 3000 });
    } catch (err) {
        toast.add({ severity: 'error', summary: t('messages.operation_failed'),
                    detail: err?.message || t('messages.operation_failed'), life: 4000 });
    } finally {
        isSaving.value = false;
    }
};

// ── Reset ───────────────────────────────────────────────────────────────────
const resetThemeColors = async () => {
    Object.assign(localTheme, { ...DEFAULT_THEME });
    if (!props.updateCardFn) return;
    isSaving.value = true;
    try {
        const payload = {
            ...props.card,
            metadata: { ...(props.card?.metadata || {}), theme: {} }
        };
        await props.updateCardFn(payload);
        savedTheme.value = {};
        toast.add({ severity: 'success', summary: t('dashboard.theme_reset_success'),
                    detail: t('dashboard.theme_reset_detail'), life: 3000 });
    } catch (err) {
        toast.add({ severity: 'error', summary: t('messages.operation_failed'), life: 4000 });
    } finally {
        isSaving.value = false;
    }
};

// ── Preset helpers ──────────────────────────────────────────────────────────
const applyPreset = (preset) => Object.assign(localTheme, { ...preset.theme });

const isActivePreset = (preset) =>
    localTheme.primaryColor     === preset.theme.primaryColor     &&
    localTheme.backgroundColor  === preset.theme.backgroundColor  &&
    localTheme.gradientEndColor === preset.theme.gradientEndColor &&
    localTheme.textColor        === preset.theme.textColor;

const isLightTheme = (preset) => {
    const hex = preset.theme.backgroundColor.replace('#', '');
    const r = parseInt(hex.slice(0, 2), 16) / 255;
    const g = parseInt(hex.slice(2, 4), 16) / 255;
    const b = parseInt(hex.slice(4, 6), 16) / 255;
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) > 0.4;
};

const activePresetKey = computed(() => THEME_PRESETS.find(p => isActivePreset(p))?.key ?? null);

const updateThemeColor = (key, value) => {
    if (isValidHexColor(value)) localTheme[key] = value;
};

// ── Luminance helpers ────────────────────────────────────────────────────────
// Returns relative luminance (0 = black, 1 = white) from a hex string
const getLuminance = (hex) => {
    const clean = (hex || '#000000').replace('#', '');
    const r = parseInt(clean.slice(0, 2), 16) / 255;
    const g = parseInt(clean.slice(2, 4), 16) / 255;
    const b = parseInt(clean.slice(4, 6), 16) / 255;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};

// Color dot style: luminance-aware ring — light colors get a slate ring so they're visible
const colorDotStyle = (hex) => {
    const lum = getLuminance(hex);
    const ring = lum > 0.6 ? '0 0 0 2px #94a3b8' : '0 0 0 2px rgba(255,255,255,0.8)';
    return {
        backgroundColor: hex,
        boxShadow: `${ring}, 0 1px 3px rgba(0,0,0,0.2)`,
    };
};

// Color swatch style: luminance-aware border — dark gets white border, light gets slate border
const colorSwatchStyle = (hex) => {
    const lum = getLuminance(hex);
    const border = lum > 0.6 ? '2px solid #cbd5e1' : '2px solid rgba(255,255,255,0.25)';
    return {
        backgroundColor: hex,
        border,
    };
};

// ── Phone simulator computed styles ─────────────────────────────────────────
const simulatorBgStyle      = computed(() => ({
    background: `linear-gradient(160deg, ${localTheme.backgroundColor} 0%, ${localTheme.gradientEndColor} 100%)`
}));
const simulatorHeroStyle    = computed(() => ({
    background: `linear-gradient(135deg, ${localTheme.backgroundColor} 0%, ${localTheme.gradientEndColor} 100%)`
}));
const simulatorPrimaryStyle = computed(() => ({ background: localTheme.primaryColor }));
const simulatorCardStyle    = computed(() => ({
    background:   `${localTheme.textColor}0d`,
    borderColor:  `${localTheme.textColor}1a`
}));
const simulatorTextStyle    = computed(() => ({ background: localTheme.textColor }));
const simulatorSubtextStyle = computed(() => ({ background: `${localTheme.textColor}66` }));
</script>

<style scoped>
/* ── Preset swatches ── */
.theme-preset-swatch {
    padding: 0;
    background: none;
    outline: none;
}
.theme-preset-swatch:focus-visible {
    outline: 2px solid #6366f1;
    outline-offset: 2px;
}

/* ── Status fade transition ── */
.fade-status-enter-active,
.fade-status-leave-active { transition: opacity 0.3s ease; }
.fade-status-enter-from,
.fade-status-leave-to    { opacity: 0; }

/* ── CSS Phone Simulator ── */
.theme-phone-simulator {
    width: var(--sim-width, 180px);
    aspect-ratio: 9 / 19.5;
    background: linear-gradient(145deg, #1f1f1f, #2a2a2a);
    border-radius: calc(var(--sim-width, 180px) * 0.06);
    padding: calc(var(--sim-width, 180px) * 0.025);
    box-shadow:
        0 30px 60px -15px rgba(0,0,0,0.4),
        0 0 0 1px rgba(255,255,255,0.08) inset,
        0 -1px 0 rgba(0,0,0,0.3) inset;
    flex-shrink: 0;
}
.theme-phone-screen {
    width: 100%; height: 100%;
    border-radius: calc(var(--sim-width, 180px) * 0.04);
    overflow: hidden;
    display: flex; flex-direction: column;
    transition: background 0.25s ease;
}
.theme-status-bar {
    display: flex; align-items: center; justify-content: space-between;
    padding: 3px 8px 2px;
    color: rgba(255,255,255,0.75);
    flex-shrink: 0;
    background: rgba(0,0,0,0.15);
}
.theme-status-time {
    font-weight: 600; font-size: 0.5rem; letter-spacing: 0.02em;
}
.theme-hero-area {
    padding: 8px 8px 6px;
    display: flex; align-items: center; gap: 6px;
    flex-shrink: 0;
    transition: background 0.25s ease;
}
.theme-hero-icon {
    width: 24px; height: 24px; border-radius: 7px;
    display: flex; align-items: center; justify-content: center;
    color: white; flex-shrink: 0;
    transition: background 0.25s ease;
}
.theme-hero-text  { flex: 1; min-width: 0; }
.theme-hero-title {
    height: 7px; border-radius: 4px; width: 70%;
    margin-bottom: 4px; opacity: 0.9;
    transition: background 0.25s ease;
}
.theme-hero-subtitle {
    height: 5px; border-radius: 3px; width: 45%;
    opacity: 0.5; transition: background 0.25s ease;
}
.theme-content-area {
    flex: 1; padding: 4px 6px;
    display: flex; flex-direction: column; gap: 4px;
    overflow: hidden;
}
.theme-content-item {
    border-radius: 6px; padding: 5px 6px;
    display: flex; align-items: center; gap: 5px;
    border: 1px solid transparent;
    transition: background 0.25s ease, border-color 0.25s ease;
}
.theme-item-dot {
    width: 8px; height: 8px; border-radius: 50%;
    flex-shrink: 0; transition: background 0.25s ease;
}
.theme-item-lines {
    flex: 1; min-width: 0;
    display: flex; flex-direction: column; gap: 3px;
}
.theme-item-line-title {
    height: 5px; border-radius: 3px;
    opacity: 0.85; transition: background 0.25s ease;
}
.theme-item-line-sub {
    height: 4px; border-radius: 2px; width: 55%;
    opacity: 0.45; transition: background 0.25s ease;
}
.theme-bottom-bar {
    padding: 4px 6px 6px;
    display: flex; justify-content: center; flex-shrink: 0;
}
.theme-action-btn {
    width: 30px; height: 30px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    color: white; box-shadow: 0 2px 10px rgba(0,0,0,0.35);
    transition: background 0.25s ease;
}
</style>
