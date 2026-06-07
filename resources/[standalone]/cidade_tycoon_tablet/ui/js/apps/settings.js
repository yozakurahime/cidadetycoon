console.log('[TycoonOS] settings.js loaded');
window.initSettings = function() {
  const audioToggle = document.getElementById('settings-audio-toggle');
  const volumeSlider = document.getElementById('settings-audio-volume');
  const wallpaperOptions = document.querySelectorAll('.wallpaper-option');
  const screen = document.getElementById('tablet-screen');

  if (audioToggle) {
    audioToggle.checked = window.OSState.soundEnabled;
    audioToggle.addEventListener('change', (e) => {
      window.OSState.soundEnabled = e.target.checked;
      localStorage.setItem('tycoon_settings_sound', window.OSState.soundEnabled);
      window.playClickSound();
    });
  }

  if (volumeSlider) {
    volumeSlider.value = window.OSState.soundVolume * 100;
    volumeSlider.addEventListener('input', (e) => {
      window.OSState.soundVolume = parseFloat(e.target.value) / 100;
      localStorage.setItem('tycoon_settings_volume', window.OSState.soundVolume);
    });
    volumeSlider.addEventListener('change', () => {
      window.playClickSound();
    });
  }

  wallpaperOptions.forEach(opt => {
    const wpNum = opt.getAttribute('data-wallpaper');
    if (wpNum === window.OSState.activeWallpaper) {
      wallpaperOptions.forEach(o => o.classList.remove('active'));
      opt.classList.add('active');
    }

    opt.addEventListener('click', () => {
      wallpaperOptions.forEach(o => o.classList.remove('active'));
      opt.classList.add('active');
      
      window.OSState.activeWallpaper = wpNum;
      localStorage.setItem('tycoon_settings_wallpaper', wpNum);
      
      if (screen) {
        screen.className = `wallpaper-gradient-${wpNum}`;
      }
      window.playClickSound();
    });
  });
};

// Inicialização automática caso a DOM já esteja carregada
if (document.readyState !== 'loading') {
  window.initSettings();
}

