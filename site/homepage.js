const tabList = document.querySelector('.section-tabs');
const tabs = [...tabList.querySelectorAll('button')];
const panels = [...document.querySelectorAll('.panel')];

function showSection(sectionId) {
  for (const panel of panels) panel.hidden = panel.id !== sectionId;
  for (const tab of tabs) {
    const selected = tab.dataset.section === sectionId;
    tab.setAttribute('aria-selected', String(selected));
    tab.tabIndex = selected ? 0 : -1;
  }
}

function showLinkedSection() {
  const target = document.getElementById(location.hash.slice(1));
  const panel = target?.closest('.panel');
  showSection(panel?.id ?? 'highlights');
  if (target && target !== panel) target.scrollIntoView();
}

tabList.hidden = false;
tabList.setAttribute('role', 'tablist');
for (const panel of panels) {
  panel.setAttribute('role', 'tabpanel');
  panel.setAttribute('aria-labelledby', `tab-${panel.id}`);
  panel.tabIndex = 0;
  panel.querySelector('.fallback-heading').hidden = true;
}
for (const [index, tab] of tabs.entries()) {
  tab.setAttribute('role', 'tab');
  tab.setAttribute('aria-controls', tab.dataset.section);
  tab.addEventListener('click', () => {
    showSection(tab.dataset.section);
    history.replaceState(null, '', `#${tab.dataset.section}`);
  });
  tab.addEventListener('keydown', (event) => {
    const destinations = {
      ArrowRight: (index + 1) % tabs.length,
      ArrowLeft: (index - 1 + tabs.length) % tabs.length,
      Home: 0,
      End: tabs.length - 1,
    };
    if (!(event.key in destinations)) return;
    event.preventDefault();
    const nextTab = tabs[destinations[event.key]];
    nextTab.focus();
    nextTab.click();
  });
}
window.addEventListener('hashchange', showLinkedSection);
showLinkedSection();
