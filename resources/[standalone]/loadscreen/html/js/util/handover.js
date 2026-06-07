/**
 * @type {NuiHandoverData}
 */
const DEFAULT_HANDOVER_DATA = {
    vars: {
        playerName: 'Player',
        serverName: 'Server',
    },
    paths: {
        images: [
            './assets/images/cidade_tycoon_logistics.jpg',
            './assets/images/cidade_tycoon_port.jpg',
            './assets/images/cidade_tycoon_enterprise.jpg',
        ],
        music: [],
        videos: ['./assets/videos/waterfall.webm'],
        logo: './assets/logo.png',
    },
    config: {
        style: 'tycoon',
        background: 'image',
        backgroundBrightness: 0.62,
        textColor: '#f8fafc',
        primaryColor: '#f1e542',
        secondaryColor: '#2ccc8a',
        shadowColor: '#05080ccc',
        fontFamily: "'Segoe UI', Arial, Helvetica, sans-serif",
        logo: true,
        serverMessage: 'Bem-vindo, ${playerName}',
        primaryBar: true,
        secondaryBar: false,
        loadingAction: false,
        finishingMessage: 'Preparando sua empresa...',
        logLine: true,
        finishedMessage: 'Cidade pronta',
        finishedLine: 'Carregando sua operacao logistica.',
        audioControls: false,
        audioMuteKey: 'Space',
        rememberVolume: true,
        errorLog: true,
        initialAudioVolume: 0,
        music: false,
        musicShuffle: false,
        imageRate: 6500,
        imageShuffle: true,
        videoShuffle: false,
        embedLink:
            'https://www.youtube.com/embed?playlist=E49ureeMykI&autoplay=1&loop=1',
        embedAccess: true,
    },
};

/**
 * @returns {NuiHandoverData}
 */
export function getHandoverData() {
    return /** @type {any} */ (window).nuiHandoverData ?? DEFAULT_HANDOVER_DATA;
}

/**
 * @readonly
 * @enum {number}
 */
const BackgroundType = {
    CSS: 0,
    Image: 1,
    Video: 2,
    Embed: 3,
};

/**
 * @param {NuiHandoverData} handoverData
 * @returns {BackgroundType}
 */
function getBackgroundType({ config: { background } }) {
    return (
        {
            image: BackgroundType.Image,
            video: BackgroundType.Video,
            embed: BackgroundType.Embed,
        }[background] ?? BackgroundType.CSS
    );
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowBackgroundCSS(handoverData) {
    return getBackgroundType(handoverData) === BackgroundType.CSS;
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowBackgroundImages(handoverData) {
    return (
        getBackgroundType(handoverData) === BackgroundType.Image &&
        handoverData.paths.images.length > 0
    );
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowBackgroundVideos(handoverData) {
    return (
        getBackgroundType(handoverData) === BackgroundType.Video &&
        handoverData.paths.videos.length > 0
    );
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowBackgroundEmbed(handoverData) {
    return (
        getBackgroundType(handoverData) === BackgroundType.Embed &&
        handoverData.config.embedLink.trim().length > 0
    );
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowLogo({ paths, config }) {
    return config.logo && typeof paths.logo !== 'undefined';
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldPlayBackgroundMusic({ paths, config }) {
    return config.music && paths.music.length > 0;
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowAudioControls(handoverData) {
    return (
        handoverData.config.audioControls &&
        (shouldShowBackgroundVideos(handoverData) ||
            shouldPlayBackgroundMusic(handoverData))
    );
}

/**
 * @param {NuiHandoverData} handoverData
 * @returns {boolean}
 */
export function shouldShowSecondaryWrapper({ config }) {
    return config.secondaryBar && config.loadingAction;
}
