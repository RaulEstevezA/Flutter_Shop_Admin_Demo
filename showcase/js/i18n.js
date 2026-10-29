import { LANGUAGE_STORAGE_KEY } from './config.js';
import { translations } from './translations.js';

function readLanguage() {
  try {
    const storedLanguage = localStorage.getItem(LANGUAGE_STORAGE_KEY);
    if (storedLanguage in translations) return storedLanguage;
  } catch (_) {
    // Storage may be disabled; the browser language remains a safe fallback.
  }

  return (navigator.language || '').toLowerCase().startsWith('es') ? 'es' : 'en';
}

export function createI18n(root = document) {
  let language = readLanguage();

  function translate(key) {
    return translations[language]?.[key] ?? translations.es[key] ?? key;
  }

  function render() {
    document.documentElement.lang = language;
    root.querySelectorAll('[data-i18n]').forEach((element) => {
      element.textContent = translate(element.dataset.i18n);
    });
    root.querySelectorAll('[data-lang]').forEach((button) => {
      button.setAttribute('aria-pressed', String(button.dataset.lang === language));
    });
  }

  function setLanguage(nextLanguage) {
    if (!(nextLanguage in translations)) return;
    language = nextLanguage;
    try {
      localStorage.setItem(LANGUAGE_STORAGE_KEY, language);
    } catch (_) {
      // Updating the visible language does not depend on persistence.
    }
    render();
  }

  function bind() {
    root.querySelectorAll('[data-lang]').forEach((button) => {
      button.addEventListener('click', () => setLanguage(button.dataset.lang));
    });
    render();
  }

  return { bind, render, setLanguage, translate };
}
