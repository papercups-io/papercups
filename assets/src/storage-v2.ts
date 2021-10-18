const PREFIX = '__papercups';

type StorageType = 'local' | 'session' | 'cookie' | 'memory' | 'none' | null;

interface Storage {
  get: (key: string) => any;
  set: (key: string, value: any) => void;
  remove: (key: string) => any;
}

type FallbackStorage = Storage & {
  _db: Record<string, any>;
  getItem: (key: string) => any;
  setItem: (key: string, value: any) => void;
  removeItem: (key: string) => any;
};

const keyify = (key: string) => `${PREFIX}:${key}`;

const wrapFallbackStorage = (): FallbackStorage => {
  return {
    _db: {},
    getItem(key: string) {
      return this._db[key] || null;
    },
    setItem(key: string, value: any) {
      this._db[key] = value;
    },
    removeItem(key: string) {
      delete this._db[key];
    },
    // Aliases
    get(key: string) {
      return this._db[key] || null;
    },
    set(key: string, value: any) {
      this._db[key] = value;
    },
    remove(key: string) {
      delete this._db[key];
    },
  };
};

const wrapLocalStorage = (): Storage => {
  try {
    const storage = localStorage || window.localStorage;

    return {
      ...storage,
      get: (key: string) => {
        const result = storage.getItem(keyify(key));

        if (!result) {
          return null;
        }

        try {
          return JSON.parse(result);
        } catch (e) {
          return result;
        }
      },
      set: (key: string, value: any) => {
        storage.setItem(keyify(key), JSON.stringify(value));
      },
      remove: (key: string) => {
        storage.removeItem(key);
      },
    };
  } catch (e) {
    return wrapFallbackStorage();
  }
};

const wrapSessionStorage = (): Storage => {
  try {
    const storage = sessionStorage || window.sessionStorage;

    // NB: this is the same as `localStorage` above
    return {
      ...storage,
      get: (key: string) => {
        const result = storage.getItem(keyify(key));

        if (!result) {
          return null;
        }

        try {
          return JSON.parse(result);
        } catch (e) {
          return result;
        }
      },
      set: (key: string, value: any) => {
        storage.setItem(keyify(key), JSON.stringify(value));
      },
      remove: (key: string) => {
        storage.removeItem(key);
      },
    };
  } catch (e) {
    return wrapFallbackStorage();
  }
};

const wrapCookieStorage = (): Storage => {
  try {
    throw new Error('Cookie storage has not been implemented!');
  } catch (e) {
    return wrapFallbackStorage();
  }
};

// FIXME: this is just a workaround until we can stop
// relying on localStorage in our chat iframe
const getPreferredStorage = (type: StorageType = 'local'): Storage => {
  try {
    switch (type) {
      case 'local':
        return wrapLocalStorage();
      case 'session':
        return wrapSessionStorage();
      case 'cookie':
        return wrapCookieStorage();
      case 'memory':
      default:
        return wrapFallbackStorage();
    }
  } catch (e) {
    return wrapFallbackStorage();
  }
};

export default class Cache {
  cache: Storage;

  constructor(options: {type?: StorageType} = {}) {
    const {type = 'local'} = options;
    const cache = getPreferredStorage(type);

    this.cache = cache;
  }

  get(key: string, fallback: any = null) {
    return this.cache.get(key) || fallback;
  }

  set(key: string, value: any) {
    return this.cache.set(key, value);
  }

  remove(key: string) {
    return this.cache.remove(key);
  }
}
