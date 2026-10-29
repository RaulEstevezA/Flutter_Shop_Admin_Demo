import { SHEET_SESSION_KEY } from './config.js';

export function createInfoSheet({ root = document, mobileQuery }) {
  const sheet = root.querySelector('.sheet');
  const backdrop = root.querySelector('.sheet-backdrop');

  function setOpen(isOpen) {
    sheet.classList.toggle('open', isOpen);
    backdrop.classList.toggle('open', isOpen);
  }

  function hasBeenSeen() {
    try {
      return sessionStorage.getItem(SHEET_SESSION_KEY) === '1';
    } catch (_) {
      return false;
    }
  }

  function markAsSeen() {
    try {
      sessionStorage.setItem(SHEET_SESSION_KEY, '1');
    } catch (_) {
      // The sheet still works when session storage is unavailable.
    }
  }

  function bind() {
    root.querySelectorAll('[data-open-sheet]').forEach((element) => {
      element.addEventListener('click', () => setOpen(true));
    });
    root.querySelectorAll('[data-close-sheet]').forEach((element) => {
      element.addEventListener('click', () => setOpen(false));
    });

    if (mobileQuery.matches && !hasBeenSeen()) {
      setOpen(true);
      markAsSeen();
    }
  }

  return { bind, setOpen };
}
