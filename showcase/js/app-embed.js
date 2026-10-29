import { APP_URL, APP_VIEWPORT } from './config.js';

export function createAppEmbed({ desktopFrame, mobileFrame, mobileQuery }) {
  const screen = desktopFrame.parentElement;

  function mount() {
    const activeFrame = mobileQuery.matches ? mobileFrame : desktopFrame;
    const inactiveFrame = mobileQuery.matches ? desktopFrame : mobileFrame;

    inactiveFrame.removeAttribute('src');
    if (!activeFrame.hasAttribute('src')) activeFrame.src = APP_URL;
  }

  function fitDesktopFrame() {
    const scale = Math.min(
      screen.clientWidth / APP_VIEWPORT.width,
      screen.clientHeight / APP_VIEWPORT.height,
    );
    screen.style.setProperty('--k', scale || 1);
    screen.style.setProperty(
      '--app-h',
      `${scale ? screen.clientHeight / scale : APP_VIEWPORT.height}px`,
    );
  }

  function start() {
    mount();
    mobileQuery.addEventListener('change', mount);

    if ('ResizeObserver' in window) {
      new ResizeObserver(fitDesktopFrame).observe(screen);
    }
    fitDesktopFrame();
  }

  return { start };
}
