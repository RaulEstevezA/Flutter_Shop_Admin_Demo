import { createAppEmbed } from './app-embed.js';
import { MOBILE_MEDIA_QUERY } from './config.js';
import { createI18n } from './i18n.js';
import { createInfoSheet } from './info-sheet.js';
import { mountInfoTemplate } from './info-template.js';

function bootstrap() {
  const mobileQuery = window.matchMedia(MOBILE_MEDIA_QUERY);

  mountInfoTemplate();
  createI18n().bind();
  createAppEmbed({
    desktopFrame: document.getElementById('desktop-app'),
    mobileFrame: document.getElementById('mobile-app'),
    mobileQuery,
  }).start();
  createInfoSheet({ mobileQuery }).bind();
}

bootstrap();
