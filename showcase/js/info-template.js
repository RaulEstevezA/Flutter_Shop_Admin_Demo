export function mountInfoTemplate(root = document) {
  const template = root.getElementById('info');
  if (!template) return;

  root.querySelectorAll('[data-info]').forEach((slot) => {
    slot.replaceChildren(template.content.cloneNode(true));
  });
}
